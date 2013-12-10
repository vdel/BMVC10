function [acc_total acc_classes table] = get_accuracy(table)
    n_classes = size(table, 1);
    
    nb_img = sum(table, 2);
    table = 100 * table ./ (repmat(nb_img, 1, n_classes)+eps);
    
    acc_classes = diag(table);
    acc_classes = acc_classes(~isnan(acc_classes));
    acc_total = sum(acc_classes) / length(acc_classes);
end