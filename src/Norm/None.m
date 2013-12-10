classdef None < NormAPI
    % No normalization
    methods (Static)
        %------------------------------------------------------------------
        % No normalization
        function A = normalize_columns(A)
        end

        function A = normalize_lines(A)
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString()
            str = 'None';
        end
        function str = toFileName()
            str = 'None';
        end
        function str = toName()
            str = 'None';
        end        
    end
end
