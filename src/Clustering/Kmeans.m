classdef Kmeans < ClusteringAPI
    
    properties (SetAccess = protected)
        lib     % Name of the lib
        lib_id  % id of the lib
        maxiter % Maximum number of iterations allowed
    end
    
    methods
        %------------------------------------------------------------------        
        function obj = Kmeans(maxiter, library)
            if nargin < 1
                maxiter = 200;
            end
            
            if nargin < 2
                library = 'mex';
            end            
            
            obj.lib = library;
            obj.maxiter = maxiter;
            
            if strcmpi(library, 'vl')
                obj.lib_id = 0;
            else
                if strcmpi(library, 'vgg')
                    obj.lib_id = 1;
                else
                    if strcmpi(library, 'ml')
                        obj.lib_id = 2;
                    else
                        if strcmpi(library, 'mex')
                            obj.lib_id = 3;
                        else
                            throw(MException('',['Unknown library for computing K-means: "' library '".\nPossible values are: "vl", "vgg", "ml" and "mex".\n']));
                        end
                    end
                end
            end            
        end   
               
        %------------------------------------------------------------------
        % Clusterize the observations X (one per line)
        function [centers obj] = clusterize(obj, X, file)
            if nargin >= 3    
                done = 0;
                if exist(file,'file') == 2
                    load(file,'centers');
                    if exist('centers','var') ~= 1
                        load(file,'c');
                        if exist('c','var') == 1
                            centers = c;
                            save(file, 'centers');
                            done = 1;
                        end
                    else
                        done = 1;
                    end
                end
                if done
                    fprintf('K-means loaded from: %s\n', file);
                    return;
                end
            end             
            
            switch obj.lib_id
            case 0  % vlfeat
                fun = @Kmeans.vlfeat;
            case 1  % vgg
                fun = @Kmeans.vgg;
            case 2  % matlab
                fun = @Kmeans.matlab;
            case 3  % mex
                fun = @Kmeans.mex;
            end
            [centers obj] = fun(X, obj.num_clusters, obj.maxiter);
            if nargin >= 3
                save(file, 'centers');
            end            
        end
        
        %------------------------------------------------------------------
        % Assign the observations X to a cluster (one per line)
        function idCluster = assign(obj, centers, X)
            [ndata, dimx] = size(X);
            [ncentres, dimc] = size(centers);
            if dimx ~= dimc
                error('Data dimension does not match dimension of centres')
            end

            n2 = repmat(sum(X.^2, 2), 1, ncentres) + ...
              repmat(sum(centers.^2, 2)', ndata, 1) - ...
              2.*(X*(centers'));          

            % Rounding errors occasionally cause negative entries in n2
            if any(any(n2<0))
              n2(n2<0) = 0;
            end            
            
            [m idCluster] = min(n2, [], 2);            
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('K-Means (Library:%s, K = %d, MaxIter = %d)', obj.lib, obj.num_clusters, obj.maxiter);
        end
        
        function str = toFileName(obj)               
            str = sprintf('KM[%s-%d-%d]', obj.lib, obj.num_clusters, obj.maxiter);
        end
        
        function str = toName(obj)
            str = sprintf('Kmeans(%d)', obj.num_clusters);
        end
    end
           
    methods (Static)
        %------------------------------------------------------------------
        function [centers obj] = vlfeat(X, K, maxiter)
            X = X';
            m = max(max(X));
            X = uint8(255/m*X);            
            [centers I] = vl_ikmeans(X, K, 'MaxIters', maxiter);
            centers = m/255*double(centers');            
            obj = sum(sqrt(sum((X - centers(I, :)) .^ 2, 2)));
        end
        
        %------------------------------------------------------------------
        function [centers obj] = vgg(X, K, maxiter)
            [centers obj] = vgg_kmeans(double(X)', K, maxiter);    
            centers = centers';
        end
        
        %------------------------------------------------------------------
        function [centers obj] = matlab(X, K, maxiter)
            [id centers obj] = kmeans(X, K, 'emptyaction', 'singleton','onlinephase','off');
            obj = sum(obj);
        end
        
        %------------------------------------------------------------------
        function [centers obj] = mex(X, K, maxiter)
            [centers, assign, obj] = kmeansmex(single(X)', K, maxiter);
            centers = centers';            
        end  
    end    
end

