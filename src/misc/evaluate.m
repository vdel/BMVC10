function [accuracy precision] = evaluate(classifier, db, target, sets_names)
    global EXPERIMENT_DIR;    

    if nargin < 3
        target = EXPERIMENT_DIR;
    end
    if nargin < 4
        sets_names = {'train' 'test'};
    end
    
    % Set to 1 if you want to force recomputing the classifiers (or remove
    % corresponding temporary files in TEMP_DIR).
    force_recompute = 0;

    path_classifier = classifier.toFileName();   
    if length(path_classifier) > 255
        path_classifier = path_classifier(1:255);
        dir = fullfile(target,path_classifier);
        if exist(dir, 'dir') == 7         
            fprintf('WARNING: The classifier file name exceeds 255 characters. It was truncated to:\n%s\nHowever a directory with the same name already exists. Make sure you are not erasing existing results !\nPRESS A KEY !\n', dir);
            pause;
        end
    else
        dir = fullfile(target,path_classifier);
    end    
    [status,message,messageid] = mkdir(target);
    [status,message,messageid] = mkdir(dir);
        
    file = fullfile(dir,'results.mat');
   
    % Init LOG file
    fprintf('Output directory:\n%s\n', dir);
    fprintf('Classifier:\n%s\n', classifier.toString()); 

    if exist(file,'file') == 2 && ~force_recompute
        fprintf('Results loaded from %s\n', file);
        load(file);                
    else
        % Train
        file = fullfile(dir,'classifier.mat');
        %file = '/data/vdelaitr/results/Willow-actions/trainval-test/SVM[1vA-cv-1-5]-[1xInter[PYR[1024-1-1x1x0.25+2x2x0.0625+4x4x0.03125-L1-KM[c-1024-200]-S[cd-300-L2T-MSD[my-1.5-12-1.2-10]]]]]-[cvxInter[PYR[1024-0-1x1x0.25+2x2x0.0625+4x4x0.03125-L1-KM[c-1024-200]-S[cd-300-L2T-MSD[my-1.5-12-1.2-10]]]]]/classifier.mat'
        tic;
        if exist(file,'file') == 2 && ~force_recompute
            load(file);
            fprintf('Classifier loaded from file %s\n',file); 
        else
            [images classes] = get_DB_images(make_DB_name(db, sets_names{1}), 'Loading training set...\n');
            [params cv_prec cv_dev_prec cv_acc cv_dev_acc] = classifier.train(images, classes);
            %save(file, 'classifier');
            save(fullfile(dir, 'cv_log.mat'), 'params', 'cv_prec', 'cv_dev_prec', 'cv_acc', 'cv_dev_acc');  
        end
        t0 = toc;

        % Test
        file = fullfile(dir,'results.mat');
        tic;
        [images classes] = get_DB_images(make_DB_name(db, sets_names{2}), 'Loading testing set...\n');
        [scores assigned_classes] = classifier.classify(images);    
        save(file,'images','classes','assigned_classes','scores');
        t1 = toc;

        % Output computation time
        fprintf('Learning time: %.02fs\n', t0);
        fprintf('Classification time: %.02fs\n', t1);    
        fprintf('Total time: %.02fs\n\n', t0+t1);    
    end
    
    % Output results
    has_subclass =~isempty(find(classes.parentID - (1:length(classes.parentID))',1));
    if has_subclass     
        fprintf('Results for subclasses:\n'); 
    else
        fprintf('Results for classes:\n');
    end
    correct_classes = cat(1, images(:).actions);
    table = confusion_table(correct_classes,assigned_classes);  
    accuracy = display_multiclass_accuracy(classes.names, table);
    precision = display_precision_recall(classes.names, correct_classes, scores);             
        
    if has_subclass
        fprintf('Results for classes:\n');
        [new_scores new_correct_classes new_assigned_classes] = convert2supclasses(classes, scores, correct_classes, assigned_classes);
        new_table = confusion_table(new_correct_classes, new_assigned_classes);  
        accuracy = display_multiclass_accuracy(classes.parentNames, new_table);
        precision = display_precision_recall(classes.parentNames, new_correct_action, new_scores); 
    end
    
    OUTPUT_LOG = 0;

    fid = fopen(fullfile(dir,'accuracy.txt'), 'w+');
    fwrite(fid, num2str(accuracy), 'char');
    fclose(fid);    
    
    fid = fopen(fullfile(dir,'precision.txt'), 'w+');
    fwrite(fid, num2str(precision), 'char');
    fclose(fid);
end

