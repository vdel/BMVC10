function perf_total = display_multiclass_accuracy(classes, table)
    n_classes = size(table, 1);
    
    [perf_total perf_classes table] = get_accuracy(table);

    fprintf('Confusion Table:\n');
 
    for i=1:n_classes
        for j=1:n_classes
            %fprintf('%.3f ', round(round(10000*table(i,j))/10)/1000);
            fprintf('%.2f ', round(round(1000*table(i,j))/10)/100);
            if j == n_classes
                fprintf('\\\\\n');
            else
                fprintf('& ');
            end
        end
    end
    
    fprintf('\nPer class accuracy:\n');
    for i=1:n_classes
        fprintf('%s: %.2f\n', classes{i}, perf_classes(i));
    end
    fprintf('-------\nMulti-class accuracy: %.2f\n', perf_total);
end

