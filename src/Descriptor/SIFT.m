classdef SIFT < DescriptorAPI
	% Sift detector
    properties (SetAccess = protected, GetAccess = protected)
        detector
        lib
        lib_name
        norm           % norm used for normalization        
    end
  
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = SIFT(detector, norm, resize, lib)           
            if nargin < 2
                norm = L2Trunc();
            end
            if nargin < 3
                resize = 0;
            end
            if nargin < 4
                lib = 'cd';
            end

            obj = obj@DescriptorAPI(resize); 
            obj.detector = detector;
            obj.norm = norm;
            obj.lib_name = lib;
                        
            if strcmpi(lib, 'cd')
                obj.lib = 0;
            else
                if strcmpi(lib, 'vl')
                    obj.lib = 1;
                else
                    throw(MException('',['Unknown library for computing SIFT descriptors: "' lib '".\nPossible values are: "cd" (for colorDescriptor) and "vl" (for vlfeat).\n']));
                end
            end
        end

        %------------------------------------------------------------------
        % Returns descriptors of the image specified by Ipath given its
        % feature points 'feat' (one per line)
        function [feat descr] = get_descriptors(obj, image, scale, zone)
            feat = obj.detector.get_features(image, scale, zone);
            if(obj.lib == 0)
                descr = obj.impl_colorDescriptor(image.path, feat, scale, image.flipped);
            else
                descr = obj.impl_vlfeat(image.path, feat, scale, image.flipped);
            end
            descr = obj.norm.normalize_lines(single(descr));   
        end        
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('SIFT[library: %s, resize: %d, norm: %s, detector: %s]',  obj.lib_name, obj.resize, obj.norm.toString(), obj.detector.toString());
        end
        function str = toFileName(obj)
            str = sprintf('S[%s-%d-%s-%s]', obj.lib_name, obj.resize, obj.norm.toFileName(), obj.detector.toFileName());
        end
        function str = toName(obj)
            det = obj.detector.toName();
            if isempty(det)  %default descriptor
                str = [];
            else                 
                str = sprintf('SIFT(%s)', det);
            end
        end        
    end
       
    methods (Static = true)
        %------------------------------------------------------------------
        function obj = loadobj(a)
            obj = a;
            if obj.lib == 0
                obj.lib_name = 'cd';
            elseif obj.lib == 1
                obj.lib_name = 'vl';                   
            end
        end    
        %------------------------------------------------------------------
        function descr = impl_colorDescriptor(Ipath, feat, scale, flip)
            [f descr] = run_colorDescriptor(Ipath, '--descriptor sift', scale, flip, feat);
        end
        
        %------------------------------------------------------------------
        function descr = impl_vlfeat(Ipath, feat, scale, flip)            
            if scale ~= 1
                I = single(imresize(rgb2gray(imread(Ipath)),scale)); 
                I(I<0) = 0;
                I(I>255) = 255;
            else
                I = single(rgb2gray(imread(Ipath))); 
            end
            if flip
                w = size(I,2);
                I = I(:,w:-1:1,:);
            end
            [f descr] = vl_sift(I,'frames',feat);
        end
    end    
end
