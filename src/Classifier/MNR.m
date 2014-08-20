
classdef MNR < ClassifierAPI 
    % Support Vector Machine Classifier

    properties
        classifier
        labels
    end
        
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = MNR(classifier)
            % input_classifier: the input classifier
            
            obj = obj@ClassifierAPI();
            obj.classifier = classifier;
        end
        
        %------------------------------------------------------------------
        % Learns from the training directory 'root', eventually do a cross
        % validation
        function train(obj, train, val, classes)
            global TEMP_DIR DB_HASH;
            
            if isempty(find([train(:).flipped], 1))
                train = reshape(train, numel(train), 1);
                train = [train; obj.flip_images(train)];
            end
            
            obj.classes = classes;
            obj.labels = cat(1,val(:).actions);                    
            
            file = fullfile(TEMP_DIR, sprintf('%d_%s.mat',DB_HASH,obj.toFileName()));          
            if exist(file,'file') == 2  
                fprintf('Loading classifier from cache: %s\n', file);
                load(file, 'classifier', 'W');
                obj.classifier = classifier;
                obj.W = W;
            else
                obj.classifier.train(train, classes);
                scores = obj.classifier.classify(val);
                
                W = mnrfit(scores, bsxfun(@rdivide, obj.labels, sum(obj.labels, 2)));
                classifier = obj.classifier;
                save(file, 'classifier', 'W');
                
                obj.W = [W zeros(size(W, 1), 1)];
            end               
        end
        
        %------------------------------------------------------------------
        % Classify the testing database 'DB'
        function [scores, assigned_classes] = classify(obj, images)
            fprintf('Classifying\n');
            scores = obj.classifier.classify(images);
            scores = [ones(size(scores, 1), 1) scores] * W;
            [~, assigned_classes] = max(scores, [], 2);
        end
        
                
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('Classifier: MNR\n%s', obj.classifier.toString());
        end
        
        function str = toFileName(obj)     
            str = sprintf('MNR-%s', obj.classifier.toFileName());  
        end
        
        function str = toName(obj)
            str = sprintf('MNR %s', obj.classifier.toName());
        end     
    end
end
