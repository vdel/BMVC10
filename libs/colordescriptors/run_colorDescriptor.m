function [feat descr] = run_colorDescriptor(Ipath, args, scale, flip, load_feat)
    global FILE_BUFFER_PATH LIB_DIR;
    
    dir = FILE_BUFFER_PATH;
    if(strcmp(computer, 'PCWIN'))
        arch = 'i386-win-vc\colorDescriptor.exe'; 
    elseif(strcmp(computer, 'GLNX86'))
        arch = 'i386-linux-gcc/colorDescriptor';
    elseif(strcmp(computer, 'GLNXA64'))
        arch = 'x86_64-linux-gcc/colorDescriptor';
    elseif(strcmp(computer, 'MACI64'))
        arch = 'x86_64-darwin-gcc/colorDescriptor';
    else            
        throw(MException('','Unknown OS'));
    end
    cmd = [fullfile(LIB_DIR,'colordescriptors',arch) ' --noErrorLog '];
    
    if(nargin == 5)
        input_file = fullfile(dir,'input');
        args = [sprintf('--loadRegions %s ', input_file) args];
        write_input(input_file, load_feat);
    end
    
    if (nargin >= 3 && scale ~= 1) || (nargin >= 4 && flip)
        warning off;
        im = imresize(imread(Ipath), scale);
        im(im<0) = 0;
        im(im>255) = 255;
        warning on;
        [d f ext] = fileparts(Ipath);
        ext = ext(2:end);
        Ipath = fullfile(FILE_BUFFER_PATH, sprintf('imgtmp.%s', ext));
        if flip
            w = size(im, 2);
            im = im(:,w:-1:1,:);
        end
        imwrite(im, Ipath, ext);
    end
    
    output_file = fullfile(dir,'output');
    args = sprintf('%s --output %s --outputFormat binary %s', Ipath, output_file, args);
    cmd = [cmd args];
    [s, m] = system(cmd);      
    [feat descr] = read_output(output_file);
end

