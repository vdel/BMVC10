classdef ClassifierAPI < handle
    % Classifier interface
    
    properties 
        classes 
        do_cv       % default: 1
    end
    
    methods
        function obj = ClassifierAPI()
            obj.do_cv = 1;
        end
        
        %------------------------------------------------------------------
        % Set CV state
        function obj = set_CV_on(obj)
            obj.do_cv = 1; 
        end  
        function obj = set_CV_off(obj)
            obj.do_cv = 0; 
        end          
    end
    
    methods (Abstract)        
        %------------------------------------------------------------------
        % Learns from the training directory 'root'
        [cv_prec cv_dev_prec cv_acc cv_dev_acc] = train(obj, images, classes)
        
        %------------------------------------------------------------------
        % Classify the testing directory 'root'
        [scores assigned_classes] = classify(obj, images)   

        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = toString(obj)
        str = toFileName(obj)
        str = toName(obj)
    end    
end

