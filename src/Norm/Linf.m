classdef Linf < NormAPI
    % Norm Linfinity
    
    properties
        norm
    end
        
    methods 
        %------------------------------------------------------------------
        % Norm Linf
        function A = normalize_columns(obj, A)
            n = max(abs(A),[],1);
            n(n == 0) = 1;
            A = (A * obj.norm) ./ repmat(n,size(A,1),1);              
        end

        function A = normalize_lines(obj, A)
            n = max(abs(A),[],2);
            n(n == 0) = 1;
            A = (A * obj.norm) ./ repmat(n,1,size(A,2));         
        end

        %------------------------------------------------------------------
        % Construtor
        function obj = Linf(norm)
            if nargin == 0
                norm = 1;
            end
            obj.norm = norm;
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('Linf (norm = %s)', num2str(obj.norm));
        end
        function str = toFileName(obj)
            if obj.norm == 1
                str = 'Linf';
            else
                str = sprintf('Linf[%s]', num2str(obj.norm));
            end                
        end
        function str = toName(obj)
            str = 'Linf';
        end    
    end
end
