classdef DescriptorAPI
    % Abstract class for descriptors
    
    properties
        resize
        % resize: indicate how the image is resized: 
        %         resize = 0  : no resize
        %         resize = n>0: the bounding box is resized so max(w,h) = n
        %         resize = n<0: the image is resized so max(w,h) = -n
    end
  
    methods     
        %------------------------------------------------------------------
        % Constructor
        function obj = DescriptorAPI(resize)
            % resize: indicate how the image is resized: 
            %         resize = 0  : no resize
            %         resize = n>0: the bounding box is resized so max(w,h) = n
            %         resize = n<0: the image is resized so max(w,h) = -n
            if nargin < 1
                resize = 0;
            end          
            obj.resize = resize;
        end            
        
        %------------------------------------------------------------------
        % Returns descriptors of the image 
        [feat descr] = get_descriptors(obj, image, scale, zone, use_cache)
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = toString(obj)
        str = toFileName(obj)
        str = toName(obj)
        
        %------------------------------------------------------------------
        % Compute the descriptors over a set of images
        function [feat descr] = compute_descriptors(obj, images, zone, use_cache)
            global TEMP_DIR DB_HASH;

            if nargin < 3
                zone = 0;
            end
            if nargin < 4
                use_cache = 1;
            end
            
            if ~ischar(DB_HASH)
                DB_HASH = sprintf('%d', DB_HASH);
            end
            
            file = fullfile(TEMP_DIR, sprintf('%s_%d-%s.mat', DB_HASH, zone, obj.toFileName()));
            if exist(file,'file') == 2 && use_cache
                fprintf('Loading descriptors from %s\n',file);
                load(file, 'feat', 'descr');
            end
            if exist('descr', 'var') == 1 && exist('feat', 'var') == 1
                fprintf('Loaded.\n');
            else    
                n_img = length(images);
                
                if obj.resize
                    if obj.resize > 0
                        bb_size = cat(1, images(:).bndbox);
                        sz = obj.resize;
                    else
                        bb_size = [ones(n_img,2) cat(1, images(:).size)];
                        sz = -obj.resize;
                    end                    
                    bb_size  = bb_size(:,3:4) - bb_size(:,1:2) + 1;
                    scales = sz ./ max(bb_size, [], 2);
                else
                    scales = ones(n_img, 1);
                end    
                
                feat  = cell(n_img, 1);
                descr = cell(n_img, 1);
                for k=1:n_img
                    fprintf('Computing descriptors for image %d of %d...\n', k, n_img);
                    [f d] = obj.get_descriptors(images(k), scales(k), zone);
                    feat{k} = f;
                    descr{k} = d;
                end
                
                for k=1:n_img
                    feat{k}(:,1:2) = feat{k}(:,1:2) / scales(k);
                end
                
                save(file, 'feat', 'descr', '-v7.3');
            end
        end
    end    
end
