function table = confusion_table(correct_labels, assigned_labels)  

    n_classes = size(correct_labels, 2);        
    table = zeros(n_classes,n_classes);
    for i = 1:size(correct_labels, 1);       
        for j = find(correct_labels(i, :))
            if assigned_labels(i, j)
                table(j, j) = table(j, j) + 1;
            else
                for k = find(assigned_labels(i,:))
                    table(j, k) = table(j, k) + 1;
                end
            end
        end
    end
end

