function build_DB_sport(path_to_DB)
    classes_names =  {'cricket_batting' 'cricket_bowling' 'croquet' 'tennis_forehand' 'tennis_serve' 'volleyball_smash'};
    traintest = {'train' 'test'};
    
    if exist(fullfile(path_to_DB, 'show_ground.m')) ~= 2
        fprintf('The path you give to build_DB_sport should be the root directory (containing show_ground.m)\nof the archive downloaded at http://www.cs.cmu.edu/~abhinavg/cvpr2007_new.zip\n\nSee Abhinav Gupta, Aniruddha Kembhavi and Larry S. Davis,\nObserving Human-Object Interactions: Using Spatial and Functional Compatibility for Recognition,\nIn Trans. on PAMI (Special Issue on Probabilistic Graphical Models).\n')
        error('Wrong path.');
    end
    
    classes = struct('name', classes_names, 'subclasses', struct('name', '', 'path', []));
    for i = 1:2
        for j=1:length(classes_names)
            classes(j).subclasses.path = fullfile(sprintf('%s/%s', classes_names{j}, traintest{i}));
        end
        file = fullfile(path_to_DB, sprintf('sport.%s.mat', traintest{i}));
        save(file, 'classes');
    end     
end

