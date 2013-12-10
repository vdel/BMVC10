classdef Dense < DetectorAPI
    % Dense features detector
    properties
        spacing
        lib
        lib_name
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = Dense(spacing, lib)     
            if(nargin < 1)
                spacing = 12;
            end            
            if(nargin < 2)
                lib = 'my';
            end
            
            obj.lib_name = lib;
            obj.spacing = spacing;
            
            if(strcmpi(lib, 'my'))
                obj.lib = 0;
            else
                if(strcmpi(lib, 'cd'))
                    obj.lib = 1;
                else
                    throw(MException('',['Unknown library for computing dense features: "' lib '".\nPossible values are: "my" (for personal implementation) and "cd" (for colorDescriptor).\n']));
                end
            end
        end
        
        %------------------------------------------------------------------
        % Returns features of the image specified by Ipath (one per line)
        % Format: X Y scale angle 0
        function feat = get_features(obj, image, img_scale, zone)
            if obj.lib == 0
                feat = obj.impl_mylib(image.path, img_scale);
            else
                feat = obj.impl_colordescriptor(image.path, img_scale);
            end      
            feat = DetectorAPI.filter_by_zone(feat, zone, image.bndbox*img_scale);
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            global BBOX_RESCALE;
            str = sprintf('DENSE[Library: %s, BBox rescale = %g, Spacing = %d]', obj.lib_name, BBOX_RESCALE, obj.spacing);
        end
        function str = toFileName(obj)
            global BBOX_RESCALE;
            str = sprintf('DENSE[%s-%g-%d]', obj.lib_name, BBOX_RESCALE, obj.spacing);
        end
        function str = toName(obj)
            str = sprintf('DENSE[%d]', obj.spacing);
        end        
    end   
    
    methods (Access = protected)
        %------------------------------------------------------------------
        function feat = impl_mylib(obj, Ipath, scale)
            n_scales = size(obj.spacing,1);
            feat = cell(n_scales,1);
            
            info = imfinfo(Ipath);
            w = info.Width * scale;
            h = info.Height * scale;
            
            for i=1:n_scales

                space = obj.spacing(i);
                coordy = ((1+space):space:(h-space))';
                coordx0 = (floor(1+space):space:(w-space))';
                coordx1 = (floor(1+3*space/2):space:(w-space))';

                n_row = size(coordy, 1);
                n_col0 = size(coordx0, 1);
                n_col1 = size(coordx1, 1);
                n = floor(n_row/2)*(n_col0+n_col1) + mod(n_row,2)*n_col1;
                feat{i} = zeros(n, 5);
                
                if size(feat{i},1) == 0
                    feat = {feat{1:i}};
                    break;
                end

                curr = 1;
                for j=1:n_row
                    if mod(j,2)
                        feat{i}(curr:(curr+n_col1-1), 1) = coordx1;
                        feat{i}(curr:(curr+n_col1-1), 2) = coordy(j);
                        curr = curr+n_col1;
                    else
                        feat{i}(curr:(curr+n_col0-1), 1) = coordx0;
                        feat{i}(curr:(curr+n_col0-1), 2) = coordy(j);
                        curr = curr+n_col0;
                    end
                end

                scale = 1.2 * obj.spacing(i) / 6;
                feat{i}(:,3) = scale * ones(n,1);
            end
            feat = cat(1, feat{:});
        end
        
        %------------------------------------------------------------------  
        function feat = impl_colordescriptor(obj, Ipath, scale)
            n_scales = size(obj.spacing,1);
            feat = cell(n_scales,1);
            for i=1:n_scales
                args = sprintf('--detector densesampling --ds_spacing %d', obj.spacing(i));
                feat{i} = run_colorDescriptor(Ipath, args, scale);
                if size(feat{i},1) == 0
                    feat = feat{1:i};
                    break;
                end
            end
            feat = cat(1, feat{:});
        end
    end    
end
