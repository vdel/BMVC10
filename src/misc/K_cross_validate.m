function [perf std_dev] = K_cross_validate(obj, K, correct_classes, params)

    % Compute folds
    n_samples = size(correct_classes,1);
    folds = cell(K,1);
    for i=1:n_samples
        folds{1+mod(i,K)} = [folds{1+mod(i,K)} i];
    end
    
    % Do cross-validation
    n_params = size(params, 1);
    perf = zeros(n_params,2);
    std_dev = zeros(n_params,2);
    
    Kperf = zeros(n_params, K, 2);
    
    for i=1:n_params 
        fprintf('Trying parameter set %d of %d...  ', i, n_params);
        tic;
        model = obj.CV_set_params(params(i,:));

        for j=1:K
            f = 1:K;
            f(j) = [];
              
            obj.CV_set_subsets(cat(2,folds{f}), folds{j});
            model = obj.CV_train(model);
            [prec acc] = obj.CV_validate(model, correct_classes(folds{j}, :));
            Kperf(i, j, :) = [prec acc];    
        end
        fprintf('(%g s)\n', toc);
    end   
    
    for i=1:n_params            
        Kperfi = reshape(Kperf(i,:,:), K, 2);
        perf(i,:) = mean(Kperfi);
        dev = Kperfi-repmat(perf(i,:),K,1);
        std_dev(i,:) = sqrt(sum(dev.*dev) / (K-1));                
    end
end
