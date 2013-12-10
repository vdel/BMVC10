function setup()     
    global TEMP_DIR EXPERIMENT_DIR BBOX_RESCALE;
    root = cd;     
    
    % The size of the bounding boxes in training and testing set are 
    % extended by a factor BBOX_RESCALE.
    BBOX_RESCALE = 1.5;
    
    % The directory were to store results.
    EXPERIMENT_DIR = fullfile(root, 'results');
    
    % A directory for temporary files. It will contain intermediate results
    % and data files to pass to external binaries (as colordescriptor).
    % Those data files will be located in the directories with random 
    % numbers in TEMP_DIR. You should remove those random directories from
    % time to time.
    TEMP_DIR = fullfile(root, 'temp');    
    
    % Check if libraries are compiled
    if isempty(dir(fullfile('libs', 'kmeans', 'kmeansmex.*')))
        cd(fullfile('libs', 'kmeans'));
        fprintf('Compiling kmeansmex\n');
        mex -output kmeansmex -DMEXFILE=1 -O kmeans.cpp;
        cd ../../;
    end
    if isempty(dir(fullfile('libs', 'svm_mex', 'bin', 'mexsvmlearn.*')))
        cd(fullfile('libs', 'svm_mex', 'matlab'));
        compilemex; 
        cd ../../../;
    end         
    
    % Set path
    libroot = fullfile(root, 'libs');    
    addpath(fullfile(root));           
    addpath(fullfile(root, 'src', 'Classifier'));
    addpath(fullfile(root, 'src', 'Clustering'));
    addpath(fullfile(root, 'src', 'Descriptor'));
    addpath(fullfile(root, 'src', 'Detector'));
    addpath(fullfile(root, 'src', 'Kernels'));
    addpath(fullfile(root, 'src', 'Norm'));
    addpath(fullfile(root, 'src', 'Signature'));
    addpath(fullfile(root, 'src', 'misc'));
    
    addpath(fullfile(libroot, 'colordescriptors'));
    addpath(fullfile(libroot, 'kmeans'));
    addpath(fullfile(libroot, 'svm_mex', 'bin'));
                                
    global LIB_DIR FILE_BUFFER_PATH;
    LIB_DIR = libroot;           
    FILE_BUFFER_PATH = fullfile(TEMP_DIR, get_rand());
    while isdir(FILE_BUFFER_PATH)
        FILE_BUFFER_PATH = fullfile(TEMP_DIR, get_rand());
    end
    
    [s, m] = mkdir(EXPERIMENT_DIR);
    [s, m] = mkdir(TEMP_DIR);
    [s, m] = mkdir(FILE_BUFFER_PATH);
end

function n = get_rand()
    n = sprintf('%d', round(rand(1)*1000000));
end
