classdef CrossValidateAPI < handle
    % API for K-fold cross-validation
    
    methods (Abstract)
        % Retrieves the training labels used for K-fold
        correct_classes = CV_get_correct_classes(obj) 
        
        % Retrieves all the values to test for cross-validation
        % 'params' must be a cell of vectors.
        params = CV_get_params(obj)

        % Set parameters
        model = CV_set_params(obj, params)
        
        % Set the training & testing sets
        obj = CV_set_subsets(obj, training_set, testing_set)
    end
    
    methods (Abstract, Static)       
        % Train on K-1 folds with some value of parameters
        model = CV_train(model)
        
        % Validate on the remaining fold
        [prec acc] = CV_validate(model, correct_classes)  
    end
end

