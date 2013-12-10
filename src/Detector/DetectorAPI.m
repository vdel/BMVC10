classdef DetectorAPI
    % Abstract class for detectors       

    methods
        %------------------------------------------------------------------
        % Returns features of the image specified by Ipath (one per line)
        % Format: X Y scale angle 0
        feat = get_features(obj, image, img_scale, zone)
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = toString(obj)
        str = toFileName(obj)
        str = toName(obj)
    end    
    
    methods (Static)        
        %------------------------------------------------------------------
        function feat = filter_by_zone(feat, zone, bndbox)
            if zone               
                is_inside = (feat(:,1) >= bndbox(1) & feat(:,1) <= bndbox(3) & feat(:,2) >= bndbox(2) & feat(:,2) <= bndbox(4));
                if zone>0
                    feat = feat(is_inside,:);
                else
                    feat = feat(~is_inside,:);
                end
            end
        end          
    end
end
