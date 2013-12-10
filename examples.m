function examples()
    % Set here your path to the databases
    path_to_DBs = '~/DB';
    
    % Uncomment the following lines to test the configurations

    % Testing on Willow-actions (download it at http://www.di.ens.fr/willow/research/stillactions/willowactions.zip)
    % See: Recognizing human actions in still images: a study of bag-of-features and part-based representations 
	% V. Delaitre, I. Laptev and J. Sivic. 
    % In Proceedings of the British Machine Vision Conference (BMVC), Aberystwyth, United Kingdom, 2010.
    path_to_DB = fullfile(path_to_DBs, 'Willow-actions');
    sets = {'trainval' 'test'}; % Could be {'train' 'val'} or {'trainval' 'test'}
    config = 'C2';              % Could be 'A', 'B', 'C1' or 'C2'    
    run_classifier(path_to_DB, sets, config); 
    
    % Testing on PPMI (download it at http://ai.stanford.edu/~bangpeng/ppmi.html)    
    % See: Grouplet: A Structured Image Representation for Recognizing Human and Object Interactions
    % B. Yao and L. Fei-Fei
    % In IEEE Conference on Computer Vision and Pattern Recognition (CVPR) 2010
    path_to_DB = fullfile(path_to_DBs, 'PPMI');
    build_DB_PPMI(path_to_DB);
    sets = {'train' 'test'};
    config = 'C2';      % Could be 'A', 'B', 'C1' or 'C2'     
    instrument = 'all'; % Could be 'all', 'bassoon', 'erhu', 'flute', 'frenchhorn', 'guitar', 'saxophone' or 'violin'
    run_classifier(fullfile(path_to_DB, instrument), sets, config); 
    
    % Testing on the Sport Database (download it at http://www.cs.cmu.edu/~abhinavg/pami2009_release.zip)
    % See: Observing Human-Object Interactions: Using Spatial and Functional Compatibility for Recognition
    % A. Gupta, A. Kembhavi and L. S. Davis
    % In Trans. on PAMI (Special Issue on Probabilistic Graphical Models)
    path_to_DB = fullfile(path_to_DBs, 'Sport');
    build_DB_sport(path_to_DB);
    sets = {'train' 'test'};
    config = 'C2';      % Could be 'A', 'B', 'C1' or 'C2'     
    run_classifier(fullfile(path_to_DB, 'sport'), sets, config);     
end