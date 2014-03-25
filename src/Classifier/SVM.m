
classdef SVM < ClassifierAPI & CrossValidateAPI
    % Support Vector Machine Classifier

    properties
        C 	        % trade-off between training error and margin (if -1, then set to default [avg. x*x]^-1, set to [] for cross-validation)
        J	        % Cost-factor, by which training errors on positive examples outweight errors on negative examples (default 1)
        N           % N-fold cross-validation
        param_cv    % remember which parameter was cross-validated
        OneVsOne    % 1 - 1vs1  // 0 - 1vsA
        kernel        
        svm
        labels                
    end
        
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = SVM(kernel, strat, C, J, N)
            % signatures: a cell containing the signature objects, one for
            % each channel
            %
            % kernels: a cell containing the kernels. Should be of the same
            % size than the signatures cell or one (in that case, the same
            % kernel is applied to the concatenation of the signatures
            %
            % strat: 'OneVsAll' or 'OneVsOne'
            %
            % C: the C parameter of the SVM. If empty C is cross-validated,
            %                                If Inf C is set to default
            %
            % J: the J parameter of the SVM.
            %
            % N: number of folds for the N-fold cross-validation
            
            if(nargin < 2)
                strat = 'OneVsAll';
            end
            if(nargin < 3)
                C = [];
            end
            if(nargin < 4)
            	J = 1;
            end
            if(nargin < 5)
            	N = 5;
            end
            
            obj = obj@ClassifierAPI();
            obj.kernel = kernel;
            obj.C = C;
            obj.J = J;
            obj.N = N;
            
            obj.param_cv = [0];
            if isempty(C)
                obj.param_cv(1) = 1;
            elseif isinf(C)
                obj.param_cv(1) = 2;                
            end

            if(strcmpi(strat, 'onevsone'))
                obj.OneVsOne = 1;
            else
                if(strcmpi(strat, 'onevsall'))
                    obj.OneVsOne = 0;
                else
                    throw(MException('',['Unknown strategie for SVM: "' strat '".\nPossible values are: "OneVsAll" and "OneVsOne".\n']));
                end
            end
            
        end
        
        %------------------------------------------------------------------
        % Learns from the training directory 'root', eventually do a cross
        % validation
        function [params cv_prec cv_dev_prec cv_acc cv_dev_acc] = train(obj, images, classes)
            global TEMP_DIR DB_HASH;
            
            obj.classes = classes;
            obj.labels = cat(1,images(:).actions);                    
            
            file = fullfile(TEMP_DIR, sprintf('%d_%s.mat',DB_HASH,obj.toFileName()));
            
            ok = 0;            
            if exist(file,'file') == 2  
                fprintf('Loading classifier from cache: %s\n', file);
                load(file, 'svm', 'best_params', 'params', 'cv_prec', 'cv_dev_prec', 'cv_acc', 'cv_dev_acc');
                if exist('best_params', 'var') == 1
                    if obj.do_cv
                        obj.CV_set_params(best_params);
                        obj.svm = svm;
                        fprintf('Loaded.\n');
                        ok = 1;
                    end
                else
                    fprintf('Failed.\n');
                end                
            end
                        
            if ~ok                                                             
                fprintf('Learn signatures...\n');
                obj.kernel.train_sigs(images);    
            
                if obj.do_cv
                    if obj.param_cv(1)
                        obj.C = obj.kernel.estimate_C();
                    end   
                
                    % Precompute distance  
                    [params best_params cv_prec cv_dev_prec cv_acc cv_dev_acc] = cross_validate(obj, obj.N);  
                    obj.CV_set_params(best_params);
                    obj.kernel.prepare_for_training();

                    obj.train_svm();                
                    svm = obj.svm; 
                
                    if length(file)<=255
                        save(file,'svm', 'params', 'best_params', 'cv_prec', 'cv_dev_prec', 'cv_acc', 'cv_dev_acc');
                    end

                    fprintf('Best parameters:\nSVM C parameter = %f\n',obj.C);
                    fprintf('Kernel parameter(s) = [%s]\n',sprintf('%.2f ',best_params(2:end)));   
                else
                    params = [];
                    cv_prec = [];
                    cv_dev_prec = [];
                    cv_acc = [];
                    cv_dev_acc = [];
                    
                    obj.kernel.prepare_for_training();
                    obj.train_svm(); 
                end                
            end
        end
        
        %------------------------------------------------------------------
        % Train the SVMs
        function obj = train_svm(obj)
            n_classes = size(obj.classes.names, 1);
                       
            n_img = size(obj.labels, 1);
                
            if obj.OneVsOne
                n_models = n_classes*(n_classes-1)/2;
                models_labels = cell(n_models, 1);
                cur_model = 0;
                for i=1:n_classes
                    for j=(i+1):n_classes
                        cur_model = cur_model + 1;
                        l = zeros(n_img, 1);
                        l(logical(obj.labels(:,i))) = 1;
                        l(logical(obj.labels(:,j))) = -1;
                        models_labels{cur_model} = l;                                        
                    end 
                end
            else
                models_labels = cell(n_classes, 1);
                for i=1:n_classes
                    l = zeros(n_img, 1);
                    l(logical(obj.labels(:,i))) = 1;
                    l(logical(~obj.labels(:,i))) = -1;
                    models_labels{i} = l;
                end
            end
        
            n_models = length(models_labels);
            obj.svm = cell(n_models, 1);
            for i=1:n_models              
                 obj.svm{i} = obj.kernel.train(obj.C, obj.J, models_labels{i});
            end           
        end
        
        %------------------------------------------------------------------
        % Classify the testing database 'DB'
        function [scores assigned_classes] = classify(obj, images)
            global DB_HASH;
            fprintf('Classifying\n');
            
            hash = DB_HASH;            
            
            batchsize = 1000;
            n_img = length(images);
            n_models = size(obj.svm, 1);
            assigned_classes = zeros(n_img, n_models);
            scores = zeros(n_img, n_models);
            
            for k = 1:batchsize:n_img
                thisbatchsize = min(batchsize, n_img-k+1);
                batch  = k:(k+thisbatchsize-1);                
                img = images(batch);
                DB_HASH = sprintf('%d_%d_%d', hash, batch(1), batch(end));
                        
                obj.kernel.prepare_for_testing(img);
                            
                [assign_c sc] = obj.classify_sigs();
                assigned_classes(batch, :) = assign_c;
                scores(batch, :) = sc;
            end
            
            DB_HASH = hash;
        end
        
        %------------------------------------------------------------------
        % Classify the given signatures
        function [assigned_classes scores] = classify_sigs(obj)
            n_img = obj.kernel.n_testing_examples;
            n_classes = size(obj.labels, 2);
                        
            assigned_classes = zeros(n_img,n_classes);
            
            if obj.OneVsOne
                n_models = n_classes * (n_classes-1) / 2;                
                vote = zeros(n_img,n_models);
                scores = zeros(n_img,n_classes);       
                cur_model = 0;
                for i=1:n_classes
                    for j=i+1:n_classes
                        cur_model = cur_model + 1;

                        s = obj.kernel.classify(obj.svm{cur_model});

                        pos = s>=0;
                        neg = s<0;

                        vote(pos,i) = vote(pos,i) + 1;
                        vote(neg,j) = vote(neg,j) + 1;                       

                        scores(pos,i) = scores(pos,i) + s(pos);
                        scores(neg,i) = scores(neg,i) + s(neg);
                        scores(pos,j) = scores(pos,j) - s(pos);                            
                        scores(neg,j) = scores(neg,j) - s(neg);                         
                    end
                end
                for i=1:n_img                    
                    j = find(vote(i,:) == max(vote(i,:)));
                    [m k] = max(scores(i,j));
                    assigned_classes(i,j(k)) = 1;
                end
            else % OneVsAll               
                scores = zeros(n_img,n_classes);   
                for i=1:n_classes
                    scores(:,i) = obj.kernel.classify(obj.svm{i});
                end
                for i=1:n_img
                    [m, j] = max(scores(i,:));
                    assigned_classes(i,j) = 1;
                end
            end      
        end
               
        %------------------------------------------------------------------
        % Retrieves the training labels used for N-fold
        function correct_classes = CV_get_correct_classes(obj)           
            correct_classes = obj.labels;
        end
               
        %------------------------------------------------------------------
        % Retrieves all the values to test for cross-validation
        % 'params' must be a cell of vectors.
        function params = CV_get_params(obj)
            params = obj.kernel.get_params();         
                       
            if obj.param_cv(1) == 1
                params = [(obj.C * 1.5.^(-10:10))' params];
            end
        end
        
        %------------------------------------------------------------------
        % Set C and kernel parameters        
        function model = CV_set_params(obj, params)
            if obj.param_cv(1) == 1
                obj.C = params(1);
            end                        
            obj.kernel.set_params(params(2:end));
            model = obj;
        end        
        
        %------------------------------------------------------------------
        % Set the training sets
        function obj = CV_set_subsets(obj, training_set, testing_set)
            obj.kernel.prepare_for_CV(training_set, testing_set);
        end
                
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            if obj.OneVsOne
                strat = 'One VS One';
            else
                strat = 'One VS All';
            end
            c = num2str(obj.C);
            str = sprintf('Classifier: SVM %s (C = %s, J = %s) %d-fold cross-validation\n%s',strat, c, num2str(obj.J), obj.N, obj.kernel.toString());
        end
        
        function str = toFileName(obj)
            if obj.OneVsOne
                strat = '1v1';
            else
                strat = '1vA';
            end
            if obj.param_cv(1) == 1
                c = 'cv';
            elseif obj.param_cv(1) == 2
                c = 'D';
            else
                c = num2str(obj.C);
            end          
            str = sprintf('SVM[%s-%s-%s-%d]-%s', strat, c, num2str(obj.J), obj.N, obj.kernel.toFileName());  
        end
        
        function str = toName(obj)
            str = sprintf('SVM %s', obj.kernel.toName());
        end     
    end
    
    methods (Static)
        %------------------------------------------------------------------
        % Train on N-1 folds (stored in 'samples') with some value of parameters
        function model = CV_train(model)
            model = model.train_svm();
        end
        
        %------------------------------------------------------------------
        % Validate on the remaining fold
        function [prec acc] = CV_validate(model, correct_classes)     
            [assigned_classes scores] = model.classify_sigs();         
            
            has_subclass =~isempty(find(model.classes.parentID - (1:length(model.classes.parentID))',1));
            if has_subclass
                [scores correct_classes assigned_classes] = convert2supclasses(model.classes, scores, correct_classes, assigned_classes);        
            end
            
            prec = get_precision(correct_classes, scores);
            acc = get_accuracy(confusion_table(correct_classes, assigned_classes));
        end
    end    
end
