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
        train(obj, images, classes)
        
        %------------------------------------------------------------------
        % Classify the testing directory 'root'
        [scores assigned_classes] = classify(obj, images)   

        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = toString(obj)
        str = toFileName(obj)
        str = toName(obj)
    end
    
    methods (Static) 
        %------------------------------------------------------------------
        % Flip images
        function fimg = flip_images(images)
            fimg = images;
            
            n = length(fimg);
            for i = 1 : n
                fimg(i).flipped = ~fimg(i).flipped;
                fimg(i).number = n + fimg(i).number;
                info = imfinfo(fimg(i).path);
                fimg(i).bndbox([1 3]) = info.Width - fimg(i).bndbox([3 1]) + 1;
            end
        end
    end    
end

