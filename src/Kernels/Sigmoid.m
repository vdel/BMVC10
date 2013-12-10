classdef Sigmoid < KernelAPI
    
    properties
        a
        b
        param_cv    % remember which parameterter was cross-validated
    end

    methods
        %------------------------------------------------------------------
        % Constructor   Kernel type: tanh(a * X.Y + b)
        % If a/b == Inf: the default value is used instead
        % If a/b == []: the parameter is cross validated        
        function obj = Sigmoid(signatures, sigs_weights, a, b)
            if nargin < 2
                sigs_weights = [];
            end            
            if nargin < 3
                a = [];
            end
            if nargin < 4
                b = [];
            end            
         
            obj = obj@KernelAPI(signatures, sigs_weights);             
            
            obj.a = a;
            obj.b = b;
            
            obj.param_cv = [0 0];
            if isempty(a)
                obj.param_cv(1) = 1;    
            elseif isinf(a)
                obj.param_cv(1) = 2;    
            end
            if isempty(b)
                obj.param_cv(2) = 1;    
            elseif isinf(b)
                obj.param_cv(2) = 2;    
            end        
        end   
    end
    
    methods %(Access = protected)                  
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = kernelToString(obj)
            str = sprintf('Sigmoid kernel: $tanh(%s * X.Y + %s)$',num2str(obj.a), num2str(obj.b));
        end
        function str = kernelToFileName(obj)
            if obj.param_cv(1) == 1
                a = 'cv';
            elseif obj.param_cv(1) == 2
                a = 'D';                
            else
                a = num2str(obj.a);
            end
            if obj.param_cv(2) == 1
                b = 'cv';
            elseif obj.param_cv(2) == 2
                b = 'D';                
            else
                b = num2str(obj.b);
            end            
            str = sprintf('Sig[%s-%s]',a,b);
        end
        function str = kernelToName(obj)
            str = 'Sig';
        end
        
        %------------------------------------------------------------------
        % Set parameters
        function [params modified] = set_kernel_params(obj, params)
            modified = (params(1) ~= obj.a || params(2) ~= obj.b);
            if isempty(modified) || modified
                obj.a = params(1);
                obj.b = params(2);
            end
            params = params(3:end);
        end        
            
        %------------------------------------------------------------------
        % Generate testing values of parameters for cross validation        
        function params = get_kernel_params(obj, pre_gram)
            % pre_gram is the matrix of scalar products
            obj.set_kernel_default_parameters(pre_gram);
            
            if obj.param_cv(1) == 1
                val_a = obj.a * 2.^(-1:1);
            else
                val_a = obj.a;
            end
            if obj.param_cv(2) == 1
                val_b = obj.b + (-2:2);
            else
                val_b = obj.b;
            end  
            
            params = {(val_a') (val_b')}';
        end
        
        %------------------------------------------------------------------
        % Set kernel's parameters to default
        function obj = set_kernel_default_parameters(obj, pre_gram)
            pre_gram = reshape(pre_gram, 1, numel(pre_gram));
            avg = mean(pre_gram);
            pre_gram = pre_gram - avg;
            stdev = sqrt(mean(pre_gram .* pre_gram));
            
            if obj.param_cv(1)
                obj.a = 1/stdev;
            end
            if obj.param_cv(2)
                obj.b = -avg/stdev;
            end            
        end                
        
        %------------------------------------------------------------------
        % Precompute distances or scalar products into the gram matrix
        % such that: gram_matrix(i,j) = <K(i)|K(j)>
        function pre_gram = precompute_gram_matrix(obj, sigs1, sigs2)
            if nargin<3
                pre_gram = sigs1' * sigs1;
            else
                pre_gram = sigs1' * sigs2;
            end
        end
        
        %------------------------------------------------------------------
        % Compute the gram matrix
        function gram = compute_gram_matrix(obj, pre_gram)
            gram = tanh(obj.a * pre_gram + obj.b);
        end   
    end
    
    methods (Static) %(Access = protected, Static)   
        %------------------------------------------------------------------
        % Modify the weight for concatenation
        function weight = weight_mod(weight)
            weight = weight * weight;
        end        
    end
end

