classdef SignatureAPI < handle
    % Signature Interface 
    properties (SetAccess = protected)
        sig_size      % Dimensionnality of the signature
        train_sigs    % Training signatures (one per column)
        norm          % Norm used to normalize signatures               
        version       % API version
    end
    
    methods
        function obj = SignatureAPI()
            obj.version = SignatureAPI.current_version();
        end
        
        % Learn the training set signatures
        train(obj, images)
        
        % Return the signature of the images (one per column)
        sigs = get_signatures(obj, images, pg, offset, scale)        
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = toString(obj)
        str = toFileName(obj)
        str = toName(obj)
    end
    
    methods (Static)
        %------------------------------------------------------------------
        function version = current_version()
            version = 2;
        end
        
        %------------------------------------------------------------------
        function obj = loadobj(a)
            if isempty(a.version)
                a.train_sigs = a.train_sigs';
            elseif a.version < 2
                a.train_sigs = a.train_sigs';
            end
            obj = a;
            obj.version = SignatureAPI.current_version();
        end              
    end    
end

