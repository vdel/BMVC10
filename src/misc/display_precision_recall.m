function mAP = display_precision_recall(classes, correct_labels, score, fig)
    if nargin<4 
        fig=0; 
    end

    n_classes = size(classes, 1);
    precision = size(n_classes, 1);
    
    fprintf('\nPer class AP:\n');
    for i=1:n_classes
        [rec,prec,ap] = precisionrecall(score(:, i), correct_labels(:,i));
        ap = ap*100;
        
        if fig
            % plot precision/recall
            name = sprintf('Action ''%s''',classes{i});
            figure('Name', name);
            plot(rec,prec,'-');
            grid;
            xlabel 'recall'
            ylabel 'precision'

            title(sprintf('%s - AP = %.3f',name, ap));
            axis([0 1 0 1])
        end
        
        precision(i) = ap;
        fprintf('%s: %.2f\n', classes{i}, ap);
    end
    
    mAP = mean(precision);        
    
    fprintf('Precision-recall average precision: %.2f\n', mAP);
end

