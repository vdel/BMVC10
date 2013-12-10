classdef NormAPI
    % Abstract class for norms    
    methods 
        %------------------------------------------------------------------
        % Normalize each line of A
        B = normalize_columns(A)
        B = normalize_lines(A)
        
        function A = normalize(obj, A)
            A = obj.normalize_columns(A);
        end     
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = toString(obj)
        str = toFileName(obj)
        str = toName(obj);
    end
end
