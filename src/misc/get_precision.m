function precision = get_precision(correct_labels, score)
    n_classes = size(correct_labels, 2);
    precision = size(n_classes, 1);       
      
    for i=1:n_classes
        [rec,prec,ap,sortind] = precisionrecall(score(:, i), correct_labels(:,i));
        precision(i) = ap*100;
    end
    
    precision = mean(precision);    
end

