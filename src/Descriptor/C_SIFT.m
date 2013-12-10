classdef C_SIFT < DescriptorAPI
	% Color Sift detector
    properties (SetAccess = protected, GetAccess = protected)
        detector
        lib
        lib_name
        norm           % norm used for normalization            
    end
     
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = C_SIFT(detector, norm, resize, lib)    
            if(nargin < 2)
                norm = L2Trunc();
            end
            if nargin < 3
                resize = 0;
            end            
            if(nargin < 4)
                lib = 'cd';
            end

            obj = obj@DescriptorAPI(resize); 
            obj.detector = detector;
            obj.norm = norm;
            obj.lib_name = lib;
                        
            if strcmpi(lib, 'cd')
                obj.lib = 0;
            else
                throw(MException('',['Unknown library for computing C-SIFT descriptors: "' lib '".\nPossible value is: "cd" (for colorDescriptor).\n']));
            end
        end
        
        %------------------------------------------------------------------
        % Returns descriptors of the image specified by Ipath given its
        % feature points 'feat' (one per line)
        function [feat descr] = get_descriptors(obj, image, scale, zone, use_cache)
            feat = obj.detector.get_features(image, scale, zone, use_cache);
            descr = obj.impl_colorDescriptor(image.path, feat, scale, image.flipped);
            descr = obj.norm.normalize_lines(single(descr));     
        end            
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('CSIFT[library: %s, resize: %d, norm: %s, detector: %s]',  obj.lib_name, obj.resize, obj.norm.toString(), obj.detector.toString());
        end
        function str = toFileName(obj)
            str = sprintf('CS[%s-%d-%s-%s]', obj.lib_name, obj.resize, obj.norm.toFileName(), obj.detector.toFileName());
        end
        function str = toName(obj)
            str = sprintf('CSIFT[%s]', obj.detector.toName());
        end  
    end

    methods (Static = true)
        %------------------------------------------------------------------
        function obj = loadobj(a)
            obj = a;
            if obj.lib == 0
                obj.lib_name = 'cd';                   
            end
        end             
        %------------------------------------------------------------------
        function descr = impl_colorDescriptor(Ipath, feat, scale, flip)
            [f descr] = run_colorDescriptor(Ipath, '--descriptor rgbsift', scale, flip, feat);
        end
    end

    methods (Access = protected)
        
    end    
end
