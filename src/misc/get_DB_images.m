function [images classes] = get_DB_images(DB, msg)
    global DB_HASH;
    
    if nargin > 1
        fprintf(msg);
    end
    
    if exist(DB, 'file') == 2
        [images classes] = get_labeled_files_myformat(DB);
    else
        [images classes] = get_labeled_files_VOC(DB);
    end
    
    actions = cat(1, images(:).actions);
    n_img_no_label = length(find(sum(actions,2) == 0));    
    if n_img_no_label ~= 0
        fprintf('WARNING: %d instances with no action specified, adding a class ''NoAction''!\n', n_img_no_label);
        ID = max(classes.parentID) + 1;
        classes.parentID(end+1) = ID;
        classes.names{end+1} = 'NoAction';
        classes.parentNames{end+1} = 'NoAction';
        for i = 1 : length(images)
            if sum(images(i).actions) == 0
                images(i).actions(end+1) = 1;
            else
                images(i).actions(end+1) = 0;
            end
        end
        actions = cat(1, images(:).actions);
    end      
    
    DB_HASH = get_hash(images);
        
    if nargin > 1
        n_classes = length(classes.names);
        fprintf('Found %d classes (%d sub-classes)\n', length(classes.parentNames), n_classes);
        fprintf('Hash ID: %d\n', DB_HASH);
        fprintf('Stats:\n');
        tot = 0;        
        for i=1:n_classes
            n_img = length(find(actions(:,i)));
            tot = tot + n_img;
            fprintf('%s: %d instances\n', classes.names{i}, n_img);
        end  
        tot = tot + n_img_no_label;
        fprintf('------------\nTotal: %d instances\n\n', tot);
    end
end

function [images classes] = get_labeled_files_VOC(DB)
    global BBOX_RESCALE;
    if isempty(BBOX_RESCALE)
        error('You should specify BBOX_RESCALE\n');
    end

    root = fileparts(DB);
    root_VOC = fileparts(fileparts(root));
    files = dir(DB);
    
    n_classes = length(files);
    classes = struct('parentID', (1:n_classes)', 'names', [], 'parentNames', []);
    classes.names = cell(n_classes, 1);    
           
    for i = 1:n_classes
        j = find(files(i).name == '_', 1) - 1;
        classes.names{i} = files(i).name(1:j);
    end
    [n, I] = sort(classes.names); 
    classes.names = classes.names(I);
    classes.parentNames = classes.names;        
    files = files(I);
    
    img = containers.Map;
    
    for i = 1:n_classes
        fid = fopen(fullfile(root, files(i).name));
        ids = cell(0,3);
        while ~feof(fid)
            line = fgetl(fid);
            ids(end+1,:) = textscan(line, '%s %d %d');
        end
        fclose(fid);
        for j = 1:size(ids,1)
            img_id = sprintf('%s@%d', ids{j,1}{1}, ids{j,2});
            if img.isKey(img_id)
                if ids{j,3} == 1
                    act = img(img_id);
                    act(i) = 1;
                    img(img_id) = act;
                end
            else
                act = zeros(1, n_classes); 
                if ids{j,3} == 1
                    act(i) = 1;
                end
                img(img_id) = act;
            end
        end
    end
       
    images = struct('path', cell(img.length(), 1), 'number', 0, 'actions', [], 'size', [], 'truncated', [], 'bndbox', [], 'fileID', [], 'bndboxID', [], 'flipped', 0);
    keys = img.keys();
    for i = 1:img.length()
        j = find(keys{i} == '@', 1);    
        img_name = keys{i}(1:(j-1));
        box_id = str2double(keys{i}((j+1):end));
        
        xml_file = fullfile(root_VOC, 'Annotations', sprintf('%s.xml', img_name));
        if exist(xml_file, 'file') ~= 2
            warning('Missing annotation file %s', xml_file);
        end
        XML = VOCreadxml(xml_file);        
        obj = XML.annotation.object;
        
        images(i).path = fullfile(root_VOC, 'JPEGImages', sprintf('%s.jpg', img_name));
        images(i).number = i;
        images(i).actions = img(keys{i});        
        images(i).size = [str2double(XML.annotation.size.width) str2double(XML.annotation.size.height)];
        images(i).truncated = 0;
        images(i).fileID = img_name;
        images(i).bndboxID = box_id;
        k = box_id;
        for j = 1:size(obj,2)
            if(strcmp(obj(j).name,'person'))
                k = k - 1;
                if k == 0
                    bb = obj(j).bndbox;
                    bb = [str2double(bb.xmin) str2double(bb.ymin) str2double(bb.xmax) str2double(bb.ymax)];
                    bb_size = bb(3:4) - bb(1:2) + 1;
                    bb = bb + [-bb_size bb_size] * (BBOX_RESCALE - 1) / 2;
                    bb = round(min(max(bb,[1 1 -Inf -Inf]), [Inf Inf images(i).size]));
                    images(i).bndbox = bb;
                end                
            end
            if k == 0
                break;
            end
        end
        if k > 0
            fprintf('Invalid person ID %d for file %s.\n', box_id, img_name);
            keyboard;
        end
    end    
end

function [images classes] = get_labeled_files_myformat(DB)
    global BBOX_RESCALE;
    BBOX_RESCALE = 1.5;   % old DB format made the BBOX 1.5 bigger
    
    c = get_classes_files(DB);
    root = fileparts(DB);
    
    n_classes = length(c);
    n_files = 0;
    n_subclasses = 0;

    [n, I] = sort({c(:).name});   
    c = c(I);
       
    for i=1:n_classes
        [n, I] = sort({c(i).subclasses(:).name});
        c(i).subclasses = c(i).subclasses(I);   
        for j=1:length(c(i).subclasses)
            n_files = n_files + length(c(i).subclasses(j).files);            
            n_subclasses = n_subclasses + 1;
        end
    end

    images = struct('path', cell(n_files, 1), 'number', 0, 'actions', [], 'size', [], 'truncated', [], 'bndbox', [], 'fileID', [], 'bndboxID', [], 'flipped', 0);
    classes = struct('parentID', zeros(n_subclasses,1), 'names', [], 'parentNames', []);
    classes.names = cell(n_subclasses, 1);    
    classes.parentNames = cell(n_classes, 1);    
    
    cur_label = 1;
    sc_id = 1;
    for i=1:n_classes
        classes.parentName{i} = c(i).name;
        n_sub = length(c(i).subclasses);
        for j=1:n_sub;
            if n_sub == 1
                classes.names{sc_id} = c(i).name;
            else
                classes.names{sc_id} = sprintf('%s-%s', c(i).name, c(i).subclasses(j).name);
            end
            classes.parentID(sc_id) = i;
            n_f = size(c(i).subclasses(j).files,1);
            for k=1:n_f
                images(cur_label+k-1).path = fullfile(root, c(i).subclasses(j).path, c(i).subclasses(j).files{k});
                images(cur_label+k-1).number = cur_label+k-1;
                images(cur_label+k-1).actions = zeros(1,n_subclasses); 
                images(cur_label+k-1).actions(sc_id) = 1; 
                [bb bb_cropped w h] = get_bb_info(images(cur_label+k-1).path);
                images(cur_label+k-1).size = [w h];
                images(cur_label+k-1).truncated = bb_cropped(1);
                images(cur_label+k-1).bndbox = bb_cropped(2:5);
                [d f e] = fileparts(c(i).subclasses(j).files{k});
                images(cur_label+k-1).fileID = f;
                images(cur_label+k-1).bndboxID = 1;
                images(cur_label+k-1).flipped = 0;
            end                    
            cur_label = cur_label + n_f;
            sc_id = sc_id + 1;
        end        
    end
end

function [bb bb_img_cropped w h] = get_bb_info(img)
    [d f] = fileparts(img);
    info = imfinfo(img);
    w = info.Width;
    h = info.Height;

    try
        bb = load(fullfile(d, sprintf('%s.info', f)), '-ascii');
        bb_img_cropped(1) = bb(1);
        bb_img_cropped(2) = max(1, bb(2));
        bb_img_cropped(3) = max(1, bb(3));
        bb_img_cropped(4) = min(w, bb(4));
        bb_img_cropped(5) = min(h, bb(5));
    catch 
        bb = [0 1 1 w h];
        bb_img_cropped = bb;     
    end
end

function classes = get_classes_files(DB)
    load(DB, 'classes'); % loads array of struct(name : string, subclasses : struct(name, path))
    root = fileparts(DB);
  
    for i=1:length(classes)
        for j=1:length(classes(i).subclasses)
            jpg_files = get_files(fullfile(root,classes(i).subclasses(j).path), 'jpg');            
            png_files = get_files(fullfile(root,classes(i).subclasses(j).path), 'png');            
            classes(i).subclasses(j).files = cat(1,jpg_files, png_files);
        end
    end
end

function files = get_files(root, ext)
    if nargin < 2
        ext = '*';
    end
    files = dir(fullfile(root,sprintf('*.%s',ext)));
    files = files(~[files(:).isdir]);
    files = {files(:).name}';
end

function classes = get_classes_names(directory)
    files = dir(directory);
    classes = {files([files(:).isdir] & not(strcmp({files(:).name},'.') | strcmp({files(:).name},'..'))).name}';
    
    i=1;
    while(i<=length(classes))
        name = classes{i};
        if name(1) == '.'
            classes = classes([1:(i-1) (i+1):end]);
        else
            i = i+1;
        end
    end
end

