classdef MultiKernel < KernelAPI
    properties 
        kernels        
        weights
        weights_cv
    end
    
    methods        
        %------------------------------------------------------------------
        % Constructor Kernel type: a * K1(X,Y) + b * K2(X,Y)
        function obj = MultiKernel(kernels, weights) 
            % if a weight is null then its weight is cross-validated
            if nargin < 2 || isempty(weights)
                weights = zeros(1, length(kernels));
                weights(1) = 1;
            elseif length(kernels) ~= length(weights)
                error('The weight vector should as long as the kernels cell.\n');
            end 
            obj.weights = weights;            
            obj.kernels = kernels;
            obj.weights_cv = (weights == 0);
        end
        
        %------------------------------------------------------------------
        % Train the attached signatures
        function obj = train_sigs(obj, images)
            obj.n_training_examples = length(images);
            for i = 1:length(obj.kernels)
                obj.kernels{i}.train_sigs(images);
            end            
        end
        
        %------------------------------------------------------------------
        % Generate testing values of parameters for cross validation
        function params = get_params(obj)
            n_ker = length(obj.kernels); 
            
            Icv = find(obj.weights_cv);
            n_cv = length(Icv);
            obj.weights(Icv) = 0;
            
            params = cell(1,n_cv+n_ker);
            for i=1:n_cv
                params{i} = 2.^((-3:3)');
            end
            for i = 1:n_ker
                params{i+n_cv} = obj.kernels{i}.get_params();
            end            
            params = cat(2, params{:});
        end  
        
        %------------------------------------------------------------------
        % Set parameters
        function [params modified] = set_params(obj, params)
            Icv = find(obj.weights_cv);
            n_cv = length(Icv);
            modified = ~isempty(Icv) && ~isempty(find(obj.weights(Icv) ~= params(1:n_cv), 1));
            if modified
                obj.weights(Icv) = params(1:n_cv);
            end
            params = params((n_cv+1):end);

            for i = 1:length(obj.kernels)
                [params mod_ker] = obj.kernels{i}.set_params(params);
                modified = modified || mod_ker;
            end
            
            if modified
                obj.gram_matrix = obj.concatenate_gram();  
            end
        end        
        
        %------------------------------------------------------------------
        % Prepare the kernel for learning.
        % WARNING: Should be called after set_params
        function obj = prepare_for_testing(obj, images)
            obj.n_testing_examples = length(images);
            for i = 1:length(obj.kernels)
                obj.kernels{i}.compute_gram_from_images(images);
            end              
            obj.gram_matrix = obj.concatenate_gram();
            obj.write_gram_matrix(obj.gram_matrix, obj.get_test_gram_matrix_path());
        end   
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            n_ker = length(obj.kernels); 
            str = cell(1, n_ker);
            for i=1:n_ker
                if obj.weights(i) == 0
                    w = 'cv';
                else
                    w = num2str(obj.weights(i));
                end
                str{i} = sprintf('%s x %s\n', w, obj.kernels{i}.toString());
            end
            str = sprintf('Multi-kernels:\n%s', cat(2,str{:}));
        end
        function str = toFileName(obj)
            n_ker = length(obj.kernels); 
            str = cell(1, n_ker);
            for i=1:n_ker
                if obj.weights_cv(i)
                    w = 'cv';
                else
                    w = num2str(obj.weights(i));
                end                
                str{i} = sprintf('[%sx%s]', w, obj.kernels{i}.toFileName());
                if i < n_ker
                    str{i} = [str{i} '-'];
                end
            end
            str = cat(2,str{:});
        end
        function str = toName(obj)
            n_ker = length(obj.kernels); 
            str = cell(1, n_ker);
            for i=1:n_ker              
                str{i} = sprintf('%s', obj.kernels{i}.toName());
                if i < n_ker
                    str{i} = [str{i} ' '];
                end
            end
            str = ['[' cat(2,str{:}) ']'];
        end
    end

    methods %(Access = protected)                      
        %------------------------------------------------------------------
        % Concatenate the precomputed gram matrices
        function gram = concatenate_gram(obj)
            gram = zeros(size(obj.kernels{1}.gram_matrix));            
            for i=1:length(obj.kernels)
                gram = gram + obj.weights(i) * obj.kernels{i}.gram_matrix;
            end
        end
        
        %------------------------------------------------------------------
        % Return the default gram matrix
        function gram = get_default_gram_matrix(obj)
            obj.weights(logical(obj.weights_cv)) = 1;
            
            for i = 1:length(obj.kernels)
                obj.kernels{i}.gram_matrix = obj.kernels{i}.get_default_gram_matrix();
            end
            
            obj.gram_matrix = obj.concatenate_gram();
            gram = obj.gram_matrix;
        end
        
        %------------------------------------------------------------------
        % Unused fonctions
        function params = get_kernel_params(obj, pre_gram)
            params = [];
        end
        function params = set_kernel_params(obj, params)
        end
        function obj = set_kernel_default_parameters(obj, pre_gram)
        end
        function pre_gram = precompute_gram_matrix(obj, sigs1, sigs2)
            pre_gram = [];
        end
        function gram = compute_gram_matrix(obj, gram)
        end
        function str = kernelToString(obj)
            str = '';
        end
        function str = kernelToFileName(obj)
            str = '';
        end
        function str = kernelToName(obj)          
            str = '';
        end
    end

    methods (Static) %(Access = protected, Static)
        function weight = weight_mod(weight)  
        end
    end
end

