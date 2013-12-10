classdef MS_Dense < Dense
    
    properties
        scale
        num_scale
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = MS_Dense(spacing, scale, s_start, s_end, lib)          
            if(nargin < 1)
                spacing = 12;
            end
            if(nargin < 2)
                scale = 1.2;
            end
            if(nargin < 3)
                num_scale = 10;
            end 
            if nargin >= 4
                if ischar(s_end)
                    lib = s_end;
                    num_scale = s_start;
                else
                    spacing = spacing * (scale ^ s_start);
                    num_scale = s_end - s_start + 1;
                    if nargin < 5
                       lib = 'my';
                    end 
                end
            else
                lib = 'my';
            end
            
            obj = obj@Dense(floor(spacing*(scale).^(0:(num_scale-1)))',lib);
            obj.scale = scale;
            obj.num_scale = num_scale;
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            global BBOX_RESCALE;
            str = sprintf('DENSE[Library: %s, BBox rescale = %g, Spacing = %d%s]', obj.lib_name, BBOX_RESCALE, obj.spacing(1), sprintf('-%d',obj.spacing(2:end)));
        end
        function str = toFileName(obj)  
            global BBOX_RESCALE;
            str = sprintf('MSD[%s-%g-%g-%g-%d]', obj.lib_name, BBOX_RESCALE, obj.spacing(1), obj.scale, obj.num_scale);
        end
        function str = toName(obj)
            if obj.spacing(1) == 12 && obj.scale == 1.2 && obj.num_scale == 10  %default detector
                str = [];
            else if obj.scale == 1.2
                    str = sprintf('%g-%d', obj.spacing(1), obj.num_scale);
                else                
                    str = sprintf('%g-%g-%d', obj.spacing(1), obj.scale, obj.num_scale);
                end
            end
        end
    end
end
