function [new_score new_correct_label new_assigned_label] = convert2supclasses(classes, score, correct_classes, assigned_classes)   
    n_img = size(score, 1);
    n_classes = length(classes.parentNames);
    new_score = zeros(n_img, n_classes);
    new_correct_label  = zeros(n_img, n_classes);
    new_assigned_label = zeros(n_img, n_classes);

    for i=1:n_classes
        new_score(:,i) = max(score(:,classes.parent == i), [], 2);            
    end

    for i=1:lengtth(classes.parent)
        new_correct_label(correct_classes(i), classes.parent(i)) = 1;
        new_assigned_label(assigned_classes(i), classes.parent(i)) = 1;
    end
end