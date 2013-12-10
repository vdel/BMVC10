classdef Intersection < KernelAPI
    
    methods        
        %------------------------------------------------------------------
        % Constructor Kernel type: sum_i(min(Xi, Yi))
        function obj = Intersection(signatures, sigs_weights)
            if nargin < 2
                sigs_weights = [];
            end       

            obj = obj@KernelAPI(signatures, sigs_weights); 
        end
    end

    methods %(Access = protected)
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = kernelToString(obj)
            str = sprintf('Intersection kernel: $sum_i(min(X_i, Y_i))$');
        end
        function str = kernelToFileName(obj)
            str = 'Inter';
        end
        function str = kernelToName(obj)
            str = 'Inter';
        end
        
        %------------------------------------------------------------------
        % Set parameters
        function [params modified] = set_kernel_params(obj, params)
            modified = 0;
        end
              
        %------------------------------------------------------------------
        % Generate testing values of parameters for cross validation
        function params = get_kernel_params(obj, pre_gram)
            params = {};    
        end  
        
        %------------------------------------------------------------------
        % Set kernel's parameters to default
        function obj = set_kernel_default_parameters(obj, pre_gram)        
        end        
        
        %------------------------------------------------------------------
        % Precompute distances or scalar products into the gram matrix
        % such that: gram_matrix(i,j) = <K(i)|K(j)>
        function pre_gram = precompute_gram_matrix(obj, sigs1, sigs2)  
            n1 = size(sigs1, 2);
            if nargin<3
                is_symetric = 1;
                n2 = n1;
            else
                is_symetric = 0;
                n2 = size(sigs2, 2);                
            end
            
            pre_gram = zeros(n1,n2);

            if is_symetric
                if issparse(sigs1)                    
                    for i = 1:n1                        
                        pre_gram(i,i) = sum(sigs1(:,i));
                        for j = (i+1):n2                            
                            pre_gram(i,j) = sum(min(sigs1(:,i), sigs1(:,j)));
                            pre_gram(j,i) = pre_gram(i,j);
                        end
                    end
                else                    
                    for j=1:n2
                        c = min(sigs1, repmat(sigs1(:,j), 1, n1));
                        pre_gram(1:end,j) = sum(c,1)';
                    end
                end
            else
                if issparse(sigs1) && issparse(sigs2)
                    for i = 1:n1                        
                        for j = 1:n2                            
                            pre_gram(i,j) = sum(min(sigs1(:,i), sigs2(:,j)));
                        end
                    end
                else                    
                    for j=1:n2
                        c = min(sigs1, repmat(sigs2(:,j), 1, n1));
                        pre_gram(1:end,j) = sum(c,1)';
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        % Compute the gram matrix
        function gram = compute_gram_matrix(obj, pre_gram)
            gram = pre_gram;
        end   
    end
    
    methods (Static) %(Static, Access = protected)   
        %------------------------------------------------------------------
        % Modify the weight for concatenation
        function weight = weight_mod(weight)
        end        
    end
end

