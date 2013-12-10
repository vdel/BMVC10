classdef L2Trunc < L2
    % Norm L2 with threshold truncation
    
    properties
        threshold
    end
        
    methods 
        %------------------------------------------------------------------
        % Norm L2
        function A = normalize_columns(obj, A)
            A = normalize_columns@L2(obj, A);
            max = obj.norm*obj.threshold;
            A(A>max) = max;
            A = normalize_columns@L2(obj, A);
        end
        
        function A = normalize_lines(obj, A)
            A = normalize_lines@L2(obj, A);
            max = obj.norm*obj.threshold;
            A(A>max) = max;
            A = normalize_lines@L2(obj, A);          
        end       

        %------------------------------------------------------------------
        % Construtor
        function obj = L2Trunc(threshold, norm)
            if nargin<1
                threshold = 0.2;
            end
            if nargin<2
                norm = 1;
            end
            obj = obj@L2(norm);
            obj.threshold = threshold;
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('L2 (norm = %s, truncation over %s)', num2str(obj.norm), num2str(obj.norm*obj.threshold));
        end
        function str = toFileName(obj)
            if obj.norm == 1
                if obj.threshold == 0.2
                    str = 'L2T';
                else
                    str = sprintf('L2T[%g]', obj.threshold);
                end
            else                
                str = sprintf('L2T[%g-%g]', obj.norm, obj.threshold);
            end
        end
        function str = toName(obj)
            str = 'L2T';
        end   
    end
end
