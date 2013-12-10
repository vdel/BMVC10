function [params best_params prec sd_prec acc sd_acc] = cross_validate(obj, K)
    % Compute K-fold cross validation
    % obj should be a class derived from CrossValidateAPI
        
    fprintf('Training\nCross-validation...\n');
    fprintf('Estimating parameters...  ');
    tic;
    params = obj.CV_get_params();
    fprintf('(%g s)\n', toc);
    n_params = length(params);
    
    do_cv = 0;
    for i=1:n_params
        if length(params{i}) > 1
            do_cv = 1;
            break;
        end
    end
    
    if do_cv        
        n_pos = zeros(1, n_params);
        for i=1:n_params
            n_pos(i) = length(params{i});
        end
       
        % Generating parameters
        full_params = params{1};
        for i = 2:n_params
            n1 = size(params{i},1);
            n2 = size(full_params,1);
            full_params = [repmat(full_params, n1, 1) kron(params{i},ones(n2,1))];
        end
        
        % Do K-fold cross-validation
        [perf std_dev] = K_cross_validate(obj, K, obj.CV_get_correct_classes(), full_params);

        optimize_with = perf(:,1);  % optimize precision
        %optimize_with = perf(:,2); % optimize accuracy
        
        best_params = full_params(floor(median(find(optimize_with == max(optimize_with)))),:);
       
        prec = perf(:,1);
        acc  = perf(:,2);
        sd_prec = std_dev(:,1);
        sd_acc  = std_dev(:,2);
        
        if length(n_pos) > 1
            prec = reshape(prec,n_pos);
            acc  = reshape(acc,n_pos);
            sd_prec = reshape(sd_prec,n_pos);
            sd_acc  = reshape(sd_acc,n_pos);
        end  
    else
        best_params = zeros(1,length(params));
        for i=1:length(params)
            best_params(i) = params{i};
        end
        prec = [];
        sd_prec = [];
        acc = [];
        sd_acc = [];
    end
end