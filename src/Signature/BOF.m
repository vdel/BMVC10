classdef BOF < SignatureAPI
    % Bag of features
    properties
        descriptor
        K     
        L          % grids for spatial pyramid
        L_cv
        centers   
        clustering
        zone       % if zone is not null, the features should be inside the bounding box if zone>0
                   %                                         or outside the bounding box if zone<0
                   % For zone = 0 pyramid is over the whole image
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = BOF(descriptor, K, norm, L, zone, clustering)
            % descriptor: An object of class descriptor
            %
            % K: dictionnary size
            %
            % norm: how the histograms are normalized
            %
            % L: the spatial pyramid. Either an array [#regionX #regionY weightRegion; ...]
            %                         or a scalar with the number of
            %                         levels: L=0 is equivalent to a simple
            %                         BOF. 
            %                         If weightRegion = 0 the weight is set
            %                         to a default value.
            %            
            % zone: 1: signature of the bounding box only
            %       0: signature of full image
            %      -1: signature of all except the bounding box
            %            
            % clustering: the clustering object used to compute the Kmeans
            
            if nargin < 4 || isempty(L)
                L = [1 1 1];
            end     
            if isscalar(L)
                levels = (0:L)';
                w = 1./2.^(L-levels+1);                
                w(1) = 1/2^L;
%                 w = 3./4.^(L-levels+1);
%                 w(1) = 1/4^L;                
                L = [2.^levels, 2.^levels, w];         
                n_cells = L(:,1).*L(:,2);
                L(:,3) = L(:,3) ./ n_cells; % each cell is normalised so we divide 
                                            % by the number of cells to have a unit
                                            % norm grid
            end
            if nargin < 5
                zone = 0;
            end
            if nargin < 6
                clustering = Kmeans;
            end
           
            obj = obj@SignatureAPI();
            obj.descriptor = descriptor;
            obj.K = K;
            obj.zone = zone;
            obj.clustering = clustering;
            obj.clustering.set_cluster_number(K);
            
            n_cells = sum(L(:,1).*L(:,2));
            end_index = cumsum(L(:,1).*L(:,2));
            beg_index = [0; end_index(1:(end-1))];
            obj.L = [L (beg_index*K+1) (end_index*K)];
            obj.L_cv = (L(:,3) == 0);
            obj.sig_size = K*n_cells;
            obj.norm = norm;
        end
        
        %------------------------------------------------------------------
        % Learn the training set signature
        function obj = train(obj, images)          
            global TEMP_DIR DB_HASH;
            
            file = fullfile(TEMP_DIR, sprintf('%d_%s.mat', DB_HASH,obj.toFileName()));
            
            if exist(file,'file') == 2
                fprintf('Loading signatures from cache: %s\n', file);
                load(file,'centers','train_sigs');
                obj.centers = centers;
                if size(train_sigs,1) == length(images) && size(train_sigs,2) == obj.sig_size
                    obj.train_sigs = train_sigs';
                else
                    obj.train_sigs = train_sigs;                                
                end
                fprintf('Loaded.\n');
            else    
                fprintf('Learning training signatures\n');

                % Compute visual vocabulary 
				[centers feat descr] = obj.compute_vocabulary(images);
                obj.centers = centers;
                
                % Compute signature
                fprintf('Computing signatures...\n');
                obj.train_sigs = obj.compute_signatures(feat, descr, images);
                               
                train_sigs = obj.train_sigs;
                save(file,'centers','train_sigs');
            end
        end
        
        %------------------------------------------------------------------
        function [vocab feat descr] = compute_vocabulary(obj, images)	       
            global DB_HASH;
		        
            % Compute descriptors
            [feat descr] = obj.descriptor.compute_descriptors(images, obj.zone, 1);                                 
                           
            % Compute visual vocabulary                
            N = 100000;
            nimg = length(descr);
            X = cell(nimg, 1);
            for i = 1 : nimg
                nselect = round(N / (nimg - i + 1));                
                nfeat = size(descr{i}, 1);
                if nselect >= nfeat
                    N = N - nfeat;
                    X{i} = descr{i};
                    continue;
                end
                select = randperm(nfeat);
                select = select(1 : nselect);
                N = N - nselect;
                X{i} = descr{i}(select, :);                
            end
            X = cat(1, X{:});
            fprintf('Computing BOF... (using %d descriptors)\n', size(X,1));   
            vocab = obj.clustering.clusterize(X, obj.clusterToName(DB_HASH));
            clear('X');
        end        
        
        %------------------------------------------------------------------
        % Return the signature of the Images
        function sigs = get_signatures(obj, images)  
            
            % Compute descriptors
            fprintf('Computing descriptors...\n');
            [feat descr] = obj.descriptor.compute_descriptors(images, obj.zone, 1);                       
            
            % Compute signature
            fprintf('Computing signatures...\n');
            sigs = obj.compute_signatures(feat, descr, images);            
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:             
        function str = get_pyramid(obj)
            n_grid = size(obj.L, 1);
            str = cell(1,n_grid);
            for i = 1:n_grid
                if obj.L_cv(i)
                    w = '?';
                else
                    w = num2str(obj.L(i,3));
                end
                str{i} = sprintf('%dx%dx%s', obj.L(i,1), obj.L(i,2), w);
                if i ~= n_grid
                    str{i} = [str{i} '+'];
                end
            end
            str = cat(2, str{:});
        end
        
        function str = toString(obj)
            descrp = obj.descriptor.toString();
            n = obj.norm.toString();    
            if size(obj.L,1) == 1 && obj.L(1,1)*obj.L(1,2) == 1
                str = sprintf('Signature: Bag of features (K = %d, Zone = %d, histogram normalization: %s, %s) of %s', obj.K, obj.zone, n, obj.clustering.toString(), descrp);
            else
                str = sprintf('Signature: Spatial pyramid (K = %d, Zone = %d, L = %s, histogram normalization: %s, %s) of %s', obj.K, obj.zone, obj.get_pyramid(), n, obj.clustering.toString(), descrp);
            end
        end
        
        function str = toFileName(obj)
            descrp = obj.descriptor.toFileName();
            n = obj.norm.toFileName();     
            if size(obj.L,1) == 1 && obj.L(1,1)*obj.L(1,2) == 1
                str = sprintf('BOF[%d-%d-%s-%s-%s]', obj.K, obj.zone, n, obj.clustering.toFileName(), descrp);
            else
                str = sprintf('PYR[%d-%d-%s-%s-%s-%s]', obj.K, obj.zone, obj.get_pyramid(), n, obj.clustering.toFileName(), descrp);
            end
        end
        
        function str = toName(obj)
            descr = obj.descriptor.toName();  
            if ~isempty(descr)
                descr = [' ' descr];
            end
            
            if obj.zone == 1
                zone = 'A';
            else if obj.zone == 0
                    zone = 'B';
                else
                    zone = 'Ā';
                end
            end                
                
            n_grids = size(obj.L, 1) - 1;
            levels = (0:n_grids)';
            old_weights = 1./2.^(n_grids-levels+1);
            old_weights(1) = 1/2^n_grids;
            usual_size = 2.^levels;
            n_cells = obj.L(:,1).*obj.L(:,2);
            usual_weights = old_weights ./ n_cells;
                
            is_old_spatial_pyramid = ((obj.L(:,1) == usual_size) & (obj.L(:,2) == usual_size) & (obj.L(:,3) == old_weights));
            is_usual_spatial_pyramid = ((obj.L(:,1) == usual_size) & (obj.L(:,2) == usual_size) & (obj.L(:,3) == usual_weights));
            
            if is_usual_spatial_pyramid
                if n_grids == 0
                    str = [];
                else
                    str = sprintf(' 2D(%d)', n_grids);
                end
                str = sprintf('BOF%d %s%s%s', obj.K, zone, str, descr);
            elseif is_old_spatial_pyramid
                if n_grids == 0
                    str = [];
                else
                    str = sprintf(' 2D(old weights)(%d)', n_grids);
                end
                str = sprintf('BOF%d %s%s%s', obj.K, zone, str, descr);
            else
                if size(obj.L,1) == 1 && obj.L(1,1)*obj.L(1,2) == 1
                    str = sprintf('BOF%d %s%s', obj.K, zone, descr);
                else
                    str = sprintf('PYR%d %s %s%s', obj.K, zone, obj.get_pyramid(), descr);
                end
            end
        end 
        
        function str = clusterToName(obj, hash)
            global TEMP_DIR;
            str = fullfile(TEMP_DIR,sprintf('%d_%s-%d-%s.mat', hash, obj.clustering.toFileName(), obj.zone, obj.descriptor.toFileName()));
        end
    end
    
    methods (Access = protected)
        %------------------------------------------------------------------
        function sigs = compute_signatures(obj, feat, descr, images)
       
            n_img = length(images);
            sigs = zeros(obj.sig_size, n_img);
            for k=1:n_img
                sigs(:, k) = obj.sig_from_feat_descr(obj.clustering, obj.centers, images(k), feat{k}, descr{k}, obj.norm, obj.L, obj.zone);
            end    
            
            % Looks for the grids with null weight and set it to the
            % average chi² distance between features
            z_index = find(obj.L(:,3) == 0);
            for k=1:length(z_index)
                s = sigs(obj.L(z_index(k),4):obj.L(z_index(k),5), :);
                n_sigs = size(s, 2);
                dist = 0;
                for i=1:n_sigs
                    for j=(i+1):n_sigs
                        dist = dist + chi2(s(:,i), s(:,j));
                    end
                end    
                % Average distance
                obj.L(z_index(k), 3) = 1 / (dist / (n_sigs*(n_sigs-1)/2));
                sigs(obj.L(z_index(k),4):obj.L(z_index(k),5), :) = s * obj.L(z_index(k), 3);
            end         

            sigs = obj.norm.normalize(sigs);
        end   
    end
    
    methods (Static = true)    
        %------------------------------------------------------------------
        function obj = loadobj(a)
           obj = loadobj@SignatureAPI(a);
        end
            
        %------------------------------------------------------------------
        function sig = sig_from_feat_descr(clustering, centers, image, feat, descr, norm, L, zone)
            if size(descr, 1) == 0
                n_bin = sum(L(:,1).*L(:,2));
                sig = zeros(size(centers,1)*n_bin,1);
            else       
                n_data = size(descr,1);
                n_centers = size(centers,1);
                IDcenter = clustering.assign(centers, descr);          
                m = sparse(n_centers, n_data);
                ID = (0:(n_data-1))'*n_centers + IDcenter;
                m(ID) = 1;
                  
                if zone > 0 % We draw the grid only on the bounding box                    
                    bb = image.bndbox;
                    w = bb(3)-bb(1)+1;
                    h = bb(4)-bb(2)+1;
                    X = (feat(:,1)-bb(1))/w;
                    Y = (feat(:,2)-bb(2))/h;
                else            % We draw the grid on the full image
                    w = image.size(1);
                    h = image.size(2);                   
                    X = (feat(:,1)-1)/w;
                    Y = (feat(:,2)-1)/h;
                end
                
                n_grid = size(L, 1);             
                sig = cell(n_grid,1);
                for i = 1:n_grid
                    n_bin = L(i,1)*L(i,2);
                    s = cell(n_bin,1);
                    I = floor(X*L(i,1)) * L(i,2) + floor(Y*L(i,2)) + 1;
                    for j = 1:n_bin
                        s{j} = norm.normalize_columns(sum(m(:,I == j), 2));
                    end
                    
                    if L(i,3) ~= 0 && L(i,3) ~= 1
                        sig{i} = cat(1, s{:}) * L(i,3);
                    else
                        sig{i} = cat(1, s{:});
                    end
                end
                sig = cat(1,sig{:});
            end
        end        
    end    
end

