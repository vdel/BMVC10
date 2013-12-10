function [feat descr] = run_colorDescriptor(Ipath, args, scale, flip, load_feat)
    global FILE_BUFFER_PATH LIB_DIR;
    
    if(strcmp(computer, 'PCWIN'))
        dir = FILE_BUFFER_PATH;
        cmd = [fullfile(LIB_DIR,'colordescriptors','i386-win-vc','colorDescriptor.exe') ' --noErrorLog '];        
    else
        if(strcmp(computer, 'GLNX86'))
            dir = FILE_BUFFER_PATH;
            cmd = [fullfile(LIB_DIR,'colordescriptors','i386-linux-gcc','colorDescriptor') ' --noErrorLog '];
        else
            if(strcmp(computer, 'GLNXA64'))
                dir = FILE_BUFFER_PATH;
                cmd = [fullfile(LIB_DIR,'colordescriptors','x86_64-linux-gcc','colorDescriptor') ' --noErrorLog '];
            else            
                throw(MException('','Unknown OS'));
            end
        end
    end
    
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

