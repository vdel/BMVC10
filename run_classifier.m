function classif = run_classifier(db, set, config)  
    if nargin < 2
        set = {'trainval' 'test'};
    end    
    if nargin < 3
        config = 'C2';
    end
               
    nWords = 1024;
    detector = MS_Dense;

    if strcmp(config, 'A')
        classif = SVM(Intersection({BOF(SIFT(detector, L2Trunc, 300), nWords, L1, 2, 1)}));
    elseif strcmp(config, 'B')
        classif = SVM(Intersection({BOF(SIFT(detector, L2Trunc,-500), nWords, L1, 2, 0)}));
    elseif strcmp(config, 'C1')
        classif = SVM(MultiKernel({ ...
                      Intersection({BOF(SIFT(detector, L2Trunc, 300), nWords, L1, 2, 1)}) ...
                      Intersection({BOF(SIFT(detector, L2Trunc, 300), nWords, L1, 0,-1)}) ...
                  }));
    elseif strcmp(config, 'C2')   
        classif = SVM(MultiKernel({ ...
                      Intersection({BOF(SIFT(detector, L2Trunc, 300), nWords, L1, 2, 1)}) ...
                      Intersection({BOF(SIFT(detector, L2Trunc, 300), nWords, L1, 2, 0)}) ...
                  }));                
    else
        error('Unknown configuration!\n');
    end      
      
    global EXPERIMENT_DIR;
    if db(end) == '/'
        db(end) = [];
    end    
    [d name] = fileparts(db);          
    path_results = fullfile(EXPERIMENT_DIR, name, sprintf('%s-%s', set{1}, set{2}));  

    evaluate(classif, db, path_results, set);   
end
