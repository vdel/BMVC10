classdef Harris < DetectorAPI
    % Dense features detector
    properties
        rotInvariant   % 0 - scale invariant only, 1 - rotation and scale invariant
        harrisTh
        harrisK
        laplaceTh
        lib
        lib_name
    end
    
        
    methods (Static = true)
        %------------------------------------------------------------------
        function obj = loadobj(a)
            obj = a;
            if obj.lib == 0
                obj.lib_name = 'cd';
            end
        end    
    end
    methods (Access = protected)
        %------------------------------------------------------------------  
        function feat = impl_colorDescriptor(obj, Ipath, scale, flip)
            args = sprintf('--detector harrislaplace --harrisThreshold %s --harrisK %s --laplaceThreshold %s', num2str(obj.harrisTh), num2str(obj.harrisK), num2str(obj.laplaceTh));
            feat = run_colorDescriptor(Ipath, args, scale, flip);
        end
    end
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = Harris(rotInvariant, harrisTh, harrisK, laplaceTh, lib)
            if(nargin < 1)
                rotInvariant = 1;
            end      
            if(nargin < 2)
                harrisTh = 1e-9;
            end
            if(nargin < 3)
                harrisK = 0.06;
            end
            if(nargin < 4)
                laplaceTh = 0.03;
            end    
            if(nargin < 5)
                lib = 'cd';
            end
            
            obj.rotInvariant = rotInvariant;
            obj.lib_name = lib;
            obj.harrisTh = harrisTh;
            obj.harrisK = harrisK;
            obj.laplaceTh = laplaceTh;
            
            if(strcmpi(lib, 'cd'))
                obj.lib = 0;
            else
                throw(MException('',['Unknown library for computing Harris-Laplace features: "' lib '".\nPossible values are: "cd" (for colorDescriptor).\n']));
            end
        end
        
        %------------------------------------------------------------------
        % Returns features of the image specified by Ipath (one per line)
        % Format: X Y scale angle 0
        function feat = get_features(obj, image, img_scale, zone)
            feat = obj.impl_colorDescriptor(image.path, img_scale, image.flipped);
            feat = DetectorAPI.filter_by_zone(feat, zone, image.bndbox*img_scale);
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            global BBOX_RESCALE;
            if obj.rotInvariant
                RI = 'Rinv';
            else
                RI = 'Rdep';
            end
            str = sprintf('HARRIS[Library: %s, BBox rescale = %g, Invariant type = %s, Threshold = %s, K = %s, Laplace threshold = %s]', obj.lib_name, BBOX_RESCALE, RI, num2str(obj.harrisTh), num2str(obj.harrisK), num2str(obj.laplaceTh));
        end
        function str = toFileName(obj)
            global BBOX_RESCALE;
            if obj.rotInvariant
                RI = 'Rinv';
            else
                RI = 'Rdep';
            end
            str = sprintf('H[%s-%g-%s-%s-%s-%s]', obj.lib_name, BBOX_RESCALE, RI, num2str(obj.harrisTh), num2str(obj.harrisK), num2str(obj.laplaceTh));
        end
        function str = toName(obj)
            if obj.rotInvariant
                RI = 'Rinv';
            else
                RI = 'Rdep';
            end
            str = sprintf('HARRIS(%s)',RI);
        end
    end
end
