classdef Chi2 < KernelAPI
    
    properties
        a
        param_cv    % remember which parameterter was cross-validated
    end
   
    methods        
        %------------------------------------------------------------------
        % Constructor Kernel type: exp(-1/a*Chi2(X,Y)^2)
        % If a == Inf: the default value is used instead
        % If a == []: a is cross validated
        function obj = Chi2(signatures, sigs_weights, a)
            if nargin < 2
                sigs_weights = [];
            end
            if nargin < 3
                a = [];
            end
                        
            obj = obj@KernelAPI(signatures, sigs_weights); 
            obj.a = a;
            
            obj.param_cv = [0];
            if isempty(a)
                obj.param_cv(1) = 1;    
            elseif isinf(a)
                obj.param_cv(1) = 2;    
            end
        end
    end

    methods %(Access = protected)
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = kernelToString(obj)
            str = sprintf('Chi2 kernel: $exp(-1/%s*Chi2(X,Y)^2)$',num2str(obj.a));
        end
        function str = kernelToFileName(obj)
            if obj.param_cv(1) == 1
                a = 'cv';
            elseif obj.param_cv(1) == 2
                a = 'D';
            else
                a = num2str(obj.a);
            end
            str = sprintf('Chi2[%s]',a);
        end
        function str = kernelToName(obj)
            str = 'Chi2';
        end
        
        %------------------------------------------------------------------
        % Set parameters
        function [params modified] = set_kernel_params(obj, params)  
            modified = (params(1) ~= obj.a);
            
            if isempty(modified) || modified
                obj.a = params(1);
            end
            params = params(2:end);
        end
        
        %------------------------------------------------------------------
        % Generate testing values of parameters for cross validation
        function params = get_kernel_params(obj, pre_gram)
            % pre_gram is the matrix of Chi2 distances
            obj.set_kernel_default_parameters(pre_gram);

            if obj.param_cv(1) == 1
                val_a = obj.a * (1.5.^(-3:3));
            else
                val_a = obj.a;
            end
            params = {val_a'}';
        end
        
        %------------------------------------------------------------------
        % Set kernel's parameters to default
        function obj = set_kernel_default_parameters(obj, pre_gram)
            if obj.param_cv(1)
                obj.a = mean(mean(pre_gram));
            end
        end        
        
        %------------------------------------------------------------------
        % Compute the Chi2 distances
        function pre_gram = precompute_gram_matrix(obj, sigs1, sigs2)           
            if nargin < 3 % symetric: sigs1 = sigs2
                pre_gram = obj.get_chi2_dist(sigs1);
            else
                pre_gram = obj.get_chi2_dist(sigs1, sigs2);                
            end
        end   
        
        %------------------------------------------------------------------
        % Compute the gram matrix
        function gram = compute_gram_matrix(obj, pre_gram)
            gram = exp(-pre_gram / obj.a);
        end
    end
    
    methods (Static) %(Access = protected, Static)
        %------------------------------------------------------------------
        % Internal method for pre-computing chi2 distance between each
        % histogram
        function dist = get_chi2_dist(sigs1, sigs2)
            %------------------------------------------------------------------
        % Modify the weight for concatenation
            n1 = size(sigs1, 2);
            if nargin<2
                is_symetric = 1;
                n2 = n1;
            else
                is_symetric = 0;
                n2 = size(sigs2, 2);                
            end          
            
            % precompute the chi2 distances
            dist = zeros(n1, n2);            
              
%             tic
%             for k = 1:d
%                 t = toc;
%                 fprintf('%f\n', t*d/k); 
%                 A = repmat(sigs1(:,k),1,n2);
%                 B = repmat(sigs2(:,k)',n1,1);
%                 N = A - B;
%                 D = A + B + eps;
%                 dist(2:end,2:end) = dist(2:end,2:end) + N.*N./D;
%             end
            
%             sigs2sparse = cell(n2,1);
%             for j=1:n2
%                 sigs2sparse{j} = sparse(sigs2(j,:));
%             end
% 
%             tic
%             for i=1:n1
%                 sigs1sparse = sparse(sigs1(i,:));
%                 t = toc;
%                 fprintf('%fs\n', t*n1/i);
%                 if is_symetric
%                     dist(i+1,i+1) = 0;
%                     js = (i+1):n2;
%                 else
%                     js = 1:n2;
%                 end
%                 for j=js
%                     S = sigs1sparse + sigs2sparse{j};
%                     I = S ~= 0;
%                     D = sigs1(i,I) - sigs2(j,I);
%                     dist(i+1,j+1) = sum(D.*D ./ S(I));
%                     if is_symetric
%                         dist(j+1,i+1) = dist(i+1,j+1);
%                     end
%                 end
%             end

            if is_symetric
                for i=1:n1               
                    I = (sigs1(:,i) ~= 0);
                    rest = sum(abs(sigs1(~I,:)), 1);
                    
                    if isempty(I)
                        for j=(i+1):n2
                            dist(i,j) = rest(j);
                            dist(j,i) = dist(i,j);
                        end
                    else
                        s2 = sigs1(I,:);
                        s1 = s2(:,i);                    

                        for j=(i+1):n2
                            S = s1 + s2(:,j);
                            D = s1 - s2(:,j);
                            dist(i,j) = sum(D.*D ./ S) + rest(j);
                            dist(j,i) = dist(i,j);
                        end
                    end
                end                    
            else
                for i=1:n1               
                    I = (sigs1(:,i) ~= 0);
                    rest = sum(abs(sigs2(~I,:)), 1);
                    s1 = sigs1(I,i);
                    s2 = sigs2(I,:);
                
                    for j=1:n2
                        S = s1 + s2(:,j);
                        D = s1 - s2(:,j);
                        dist(i,j) = sum(D.*D ./ S) + rest(j);
                    end
                end
            end    
            
            dist = dist * 0.5;
        end    
        
        %------------------------------------------------------------------
        % Modify the weight for concatenation
        function weight = weight_mod(weight)
        end
    end  
end

