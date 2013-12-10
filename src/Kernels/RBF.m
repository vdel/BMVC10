classdef RBF < KernelAPI
    
    properties 
        a
        param_cv    % remember which parameterter was cross-validated
    end
    
    methods        
        %------------------------------------------------------------------
        % Constructor Kernel type: exp(-1/a*||X-Y||^2)
        % If a == Inf: the default value is used instead
        % If a == []: a is cross validated        
        function obj = RBF(signatures, sigs_weights, a)
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
            str = sprintf('RBF kernel: $exp(-1/%s*||X-Y||^2$)',num2str(obj.a));
        end
        function str = kernelToFileName(obj)
            if obj.param_cv(1) == 1
                a = 'cv';
            elseif obj.param_cv(1) == 2
                a = 'D';
            else
                a = num2str(obj.a);
            end          
            str = sprintf('RBF[%s]',a);
        end
        function str = kernelToName(obj)
            str = 'RBF';
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
            % pre_gram is the matrix of squared L2 distances            
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
        % Precompute distances or scalar products into the gram matrix
        % such that: gram_matrix(i,j) = <K(i)|K(j)>
        function gram = precompute_gram_matrix(obj, sigs1, sigs2)
            if nargin < 3 % symetric: sigs1 = sigs2
                gram = obj.prepare_L2_dist(sigs1);
            else                
                gram = obj.prepare_L2_dist(sigs1, sigs2);
            end
        end
        
        %------------------------------------------------------------------
        % Compute the gram matrix
        function gram = compute_gram_matrix(obj, pre_gram)
            gram = exp(-pre_gram / obj.a);
        end        
    end
    
    methods (Static) %(Static, Access = protected)
        function dist = prepare_L2_dist(sigs1, sigs2)
            n1 = size(sigs1, 2);
            norms1 = sum(sigs1.^2,1);
            if nargin<2
                n2 = n1;
                norms2 = norms1;
                scalars = sigs1'*sigs1;
            else
                n2 = size(sigs2, 2);                
                norms2 = sum(sigs2.^2,1);
                scalars = sigs1'*sigs2;                             
            end
            
            dist = repmat(norms1',1,n2) - 2*scalars + repmat(norms2,n1,1);
        end

        %------------------------------------------------------------------
        % Modify the weight for concatenation
        function weight = weight_mod(weight)
            weight = weight * weight;
        end
    end
end

