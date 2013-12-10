
classdef KernelAPI < handle
    properties
        signatures      % cell containing the signatures
        sigs_weights    % the signatures relative weights
        sigs_weights_cv  % remember which parameterter was cross-validated  
        precomputed_gram_matrix
        index_training_exemples
        n_training_examples
        n_testing_examples          
        gram_matrix  
    end
        
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = KernelAPI(signatures, sigs_weights)
            if nargin > 0   % happend when using Multi kernels
                % if a weight is null then its weight is cross-validated
                if nargin < 2 || isempty(sigs_weights)
                    sigs_weights = ones(1, length(signatures));
                elseif length(signatures) ~= length(sigs_weights)
                    error('The weight vector should as long as the signatures cell.\n');
                end            
                obj.signatures = signatures;
                obj.sigs_weights = sigs_weights;
                obj.sigs_weights_cv = (sigs_weights == 0);
            end
        end              
        
        %------------------------------------------------------------------
        % Train the attached signatures
        function obj = train_sigs(obj, images)
            obj.n_training_examples = length(images);
            obj.precomputed_gram_matrix = cell(length(obj.signatures),1);
            for i=1:length(obj.signatures)
                obj.signatures{i}.train(images);
                null_vect = zeros(obj.signatures{i}.sig_size,1);
                obj.precomputed_gram_matrix{i} = obj.precompute_gram_matrix([null_vect, obj.signatures{i}.train_sigs]);
            end            
        end
                             
        %------------------------------------------------------------------
        % Generate testing values of parameters for cross validation.
        % WARNING: Should be called after train_sigs.
        function params = get_params(obj)            
            Icv = find(obj.sigs_weights_cv);
            n_cv = length(Icv);
            params = cell(1,n_cv);
            for i=1:n_cv
                params{i} = 2.^((-3:3)');
            end
            
            obj.sigs_weights(Icv) = 1;            
            pre_gram = obj.concatenate_pre_gram();
            params = [params obj.get_kernel_params(pre_gram)];    
            
            % compute the gram matrix with current parameters
            obj.gram_matrix = obj.compute_gram_matrix(pre_gram);  
        end
        
        %------------------------------------------------------------------
        % Set parameters
        function [params modified] = set_params(obj, params)
            Icv = find(obj.sigs_weights_cv);
            n_cv = length(Icv);
       
            weights_mod = ~isempty(Icv) && isempty(find(obj.sigs_weights(Icv) ~= params(1:n_cv), 1));
            if weights_mod
                obj.sigs_weights(Icv) = params(1:n_cv);
            end
            [params ker_mod] = obj.set_kernel_params(params((n_cv+1):end));
            
            modified = weights_mod | ker_mod;  
            if modified
                obj.gram_matrix = obj.compute_gram_matrix(obj.concatenate_pre_gram());  
            end                
        end
               
        %------------------------------------------------------------------
        % Returns an estimate of the C parameters for the SVM
        function C = estimate_C(obj)                     
            C = 1/mean(mean(get_default_gram_matrix(obj)));
            %C = 1/mean(abs(diag(get_default_gram_matrix(obj))));
        end
              
        %------------------------------------------------------------------
        % Prepare the kernel for cross validation
        % WARNING: Should be called after set_params
        function obj = prepare_for_CV(obj, train_set, test_set)
            obj.index_training_exemples = train_set;
            obj.n_testing_examples = length(test_set);
            
            train_set = [1 (train_set+1)];   % because of the null vector
            test_set = [1 (test_set+1)];
            gram = obj.gram_matrix(train_set,:);
            obj.write_gram_matrix(gram(:,train_set), obj.get_train_gram_matrix_path());
            obj.write_gram_matrix(gram(:,test_set),  obj.get_test_gram_matrix_path());
        end
        
        %------------------------------------------------------------------
        % Prepare the kernel for learning
        % WARNING: Should be called after set_params
        function obj = prepare_for_training(obj) 
            obj.index_training_exemples = 1:obj.n_training_examples;
            obj.write_gram_matrix(obj.gram_matrix, obj.get_train_gram_matrix_path());            
        end
        
        %------------------------------------------------------------------
        % Prepare the kernel for learning.
        % WARNING: Should be called after set_params
        function obj = prepare_for_testing(obj, images)
            obj.n_testing_examples = length(images);
            obj.compute_gram_from_images(images);            
            obj.write_gram_matrix(obj.gram_matrix, obj.get_test_gram_matrix_path());
        end
                                          
        %------------------------------------------------------------------
        % Return a trained svm (labels are 1 (pos), 0 (ignore) or -1 (neg))
        function svm = train(obj, C, J, labels)  
            labels = labels(obj.index_training_exemples);
            svm = mexsvmlearn((1:length(labels))', labels, sprintf('-v 0 -c %g -j %g -t 4 -u0%s', C, J, obj.get_train_gram_matrix_path()));            
        end
        
        %------------------------------------------------------------------
        % Return scores provided a trained svm
        function scores = classify(obj, svm)       
            svm.kernel_parm.custom = sprintf('0%s',obj.get_test_gram_matrix_path());
            [err scores] = mexsvmclassify((1:obj.n_testing_examples)', zeros(obj.n_testing_examples,1), svm);
        end              
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            n_sigs = length(obj.signatures);
            str = cell(1,n_sigs);
            for i=1:n_sigs
                if obj.sigs_weights(i) == 0
                    w = 'cv';
                else
                    w = num2str(obj.sigs_weights(i));
                end
                str{i} = sprintf('--> %s x %s\n', w, obj.signatures{i}.toString());                
            end
            str = [sprintf('%s of:\n',obj.kernelToString()) cat(2,str{:})];            
        end
        
        function str = toFileName(obj)
            n_sigs = length(obj.signatures);            
            if n_sigs == 1
                str = sprintf('%s[%s]',obj.kernelToFileName(), obj.signatures{1}.toFileName());            
            else
                str = cell(1,n_sigs);
                for i=1:n_sigs
                    if obj.sigs_weights_cv(i)
                        w = 'cv';
                    else
                        w = num2str(obj.sigs_weights(i));
                    end                    
                    str{i} = sprintf('%sx%s', w, obj.signatures{i}.toFileName());                
                    if i>1
                        str{i} = ['-' str{i}];
                    end
                end
                str = sprintf('%s[%s]',obj.kernelToFileName(), cat(2,str{:}));       
            end                
        end
        
        function str = toName(obj)
            n_sigs = length(obj.signatures);
            if n_sigs == 1
                str = sprintf('%s(%s)',obj.kernelToName(), obj.signatures{1}.toName());               
            else
                str = cell(1,n_sigs);
                for i=1:n_sigs            
                    str{i} = sprintf('(%s)', obj.signatures{i}.toName());                
                    if i>1
                        str{i} = ['-' str{i}];
                    end
                end
                str = sprintf('%s(%s)',obj.kernelToName(), cat(2,str{:}));                               
            end            
        end
    end
    
    methods %(Access = protected)
        %------------------------------------------------------------------
        % Concatenate the precomputed gram matrices
        function gram = concatenate_pre_gram(obj)
            gram = zeros(size(obj.precomputed_gram_matrix{1}));            
            for i=1:length(obj.signatures)
                gram = gram + obj.weight_mod(obj.sigs_weights(i)) * obj.precomputed_gram_matrix{i};
            end
        end
        
        %------------------------------------------------------------------
        % Return the default gram matrix
        function gram = get_default_gram_matrix(obj)
            obj.sigs_weights(logical(obj.sigs_weights_cv)) = 1;
            pre_gram = obj.concatenate_pre_gram();
            obj.set_kernel_default_parameters(pre_gram);             
            obj.gram_matrix = obj.compute_gram_matrix(pre_gram);
            gram = obj.gram_matrix;
        end        

        %------------------------------------------------------------------
        % Generate testing values of kernel's parameters for cross validation
        % The precomputed gram matrix is given to allow parameter
        % estimation
        params = get_kernel_params(obj, pre_gram)
        
        %------------------------------------------------------------------
        % Set parameters        
        params = set_kernel_params(obj, params)

        %------------------------------------------------------------------
        % Set kernel's parameters to default
        obj = set_kernel_default_parameters(obj, pre_gram)     
        
        %------------------------------------------------------------------
        % Precompute the gram matrix (e.g. compute only the scalar product
        % between the signatures) --> it should be linear with respect to
        % the concatenation of the signatures:
        % We should have:
        % precompute_gram_matrix(obj, [a*S1 b*S2] , [a*S3 b*S4]) ==
        %    weight_mod(a) * precompute_gram_matrix(obj, S1, S3) + 
        %    weight_mod(b) * precompute_gram_matrix(obj, S2, S4)
        pre_gram = precompute_gram_matrix(obj, sigs1, sigs2)
              
        %------------------------------------------------------------------
        % Compute the gram matrix from the precomputed gram matrix
        % obtained from the weighted concatenation of the signatures
        gram = compute_gram_matrix(obj, pre_gram)
              
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = kernelToString(obj)
        str = kernelToFileName(obj)
        str = kernelToName(obj)            
        
        %------------------------------------------------------------------
        function obj = compute_gram_from_images(obj, images)
            obj.precomputed_gram_matrix = cell(length(obj.signatures), 1);
            for i=1:length(obj.signatures)
                null_vect = zeros(obj.signatures{i}.sig_size,1);
                sigs = obj.signatures{i}.get_signatures(images);    
                sigs = [null_vect sigs]; 
                obj.precomputed_gram_matrix{i} = obj.precompute_gram_matrix([null_vect obj.signatures{i}.train_sigs], sigs);
            end  
                           
            obj.gram_matrix = obj.compute_gram_matrix(obj.concatenate_pre_gram());
        end
    end
    
    methods (Static) %(Access = protected, Static)
        %------------------------------------------------------------------
        % Get the path to the gram matrix for training & testing
        function path = get_train_gram_matrix_path()
            global FILE_BUFFER_PATH;
            path = fullfile(FILE_BUFFER_PATH, sprintf('gram_train.mat'));
        end        
        function path = get_test_gram_matrix_path()
            global FILE_BUFFER_PATH;
            path = fullfile(FILE_BUFFER_PATH, sprintf('gram_test.mat'));
        end    
        
        %------------------------------------------------------------------
        % Store the gram matrix into a file
        function write_gram_matrix(gram, path)   
            fid = fopen(path, 'w+');            
            fwrite(fid, size(gram, 1), 'int32');
            fwrite(fid, size(gram, 2), 'int32');
            fwrite(fid, gram', 'double');
            fclose(fid);
        end        
        
        %------------------------------------------------------------------
        % Modify the weight for concatenation
        % Usually return w or w²
        weight = weight_mod(weight)        
    end
end

