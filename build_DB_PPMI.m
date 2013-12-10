function build_DB_PPMI(path_to_DB)
    traintest = {'train' 'test'};    
    classes_names = dir(fullfile(path_to_DB, 'norm_image', 'play_instrument'));
    classes_names = {classes_names(:).name};
    classes_names = classes_names(~strcmp(classes_names, '.'));
    classes_names = classes_names(~strcmp(classes_names, '..'));        
    
    if length(classes_names) == 0
        fprintf('The path you give to build_DB_PPMI should be the directory where you unzipped\nthe archive downloaded at http://vision.stanford.edu/Datasets/norm_ppmi_7class.zip\n\nSee Bangpeng Yao and Li Fei-Fei.\nGrouplet: A Structured Image Representation for Recognizing Human and Object Interactions.\nIEEE Conference on Computer Vision and Pattern Recognition (CVPR), 2010\n')
        error('Wrong path.');
    else
        fprintf('Found %d classes:\n%s\n', length(classes_names), sprintf('  - %s\n', classes_names{:}));
    end
 
    classes = struct('name', classes_names, 'subclasses', struct('name', {'play' 'with'}, 'path', []));
    for i = 1:2
        for j=1:7
            classes(j).subclasses(1).path = fullfile('norm_image', 'play_instrument', classes_names{j}, traintest{i});
            classes(j).subclasses(2).path = fullfile('norm_image', 'with_instrument', classes_names{j}, traintest{i});
        end
        file = sprintf('all.%s.mat', traintest{i});
        save(fullfile(path_to_DB, file), 'classes');
    end
        
    for j=1:7
        pos = sprintf('%s+', classes_names{j});
        neg = sprintf('%s-', classes_names{j});
        classes = struct('name', {pos neg}, 'subclasses', struct('name', '', 'path', []));
        for i= 1:2
            classes(1).subclasses.path = fullfile('norm_image', 'play_instrument', classes_names{j}, traintest{i});
            classes(2).subclasses.path = fullfile('norm_image', 'with_instrument', classes_names{j}, traintest{i});
            file = sprintf('%s.%s.mat', classes_names{j}, traintest{i});
            save(fullfile(path_to_DB, file), 'classes');
        end
    end    
end

