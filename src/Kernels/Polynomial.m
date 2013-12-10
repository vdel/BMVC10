classdef Polynomial < KernelAPI
    
    properties
        a
        b
        c
        param_cv    % remember which parameterter was cross-validated
    end
    
    methods        
        %------------------------------------------------------------------
        % Constructor   Kernel type: (a * X.Y + b)^c
        % If a/b/c == Inf: the default value is used instead
        % If a/b/c == []: the parameter is cross validated     
        function obj = Polynomial(signatures, sigs_weights, a, b, c)
            if nargin < 2
                sigs_weights = [];
            end            
            if nargin < 3
                a = [];
            end
            if nargin < 4
                b = [];
            end       
            if nargin < 5
                c = [];
            end            
            
            obj = obj@KernelAPI(signatures, sigs_weights);        
            
            obj.a = a;
            obj.b = b;
            obj.c = floor(c);
            
            obj.param_cv = [0 0 0];
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
            if isempty(c)
                obj.param_cv(3) = 1;    
            elseif isinf(c)
                obj.param_cv(3) = 2;    
            end                     
        end
    end

    methods %(Access = protected)                
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = kernelToString(obj)
            str = sprintf('Polynomial kernel: $(%s * X.Y + %s)^%d$',num2str(obj.a), num2str(obj.b), obj.c);
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
            if obj.param_cv(3) == 1
                c = 'cv';
            elseif obj.param_cv(3) == 2
                c = 'D';                
            else
                c = num2str(obj.c);
            end              
            str = sprintf('Poly[%s-%s-%d]',a,b,c);
        end
        function str = kernelToName(obj)
            str = 'Poly';
        end
        
        %------------------------------------------------------------------
        % Set parameters
        function [params modified] = set_kernel_params(obj, params)
            modified = (params(1) ~= obj.a || params(2) ~= obj.b || params(3) ~= obj.c);
            
            if isempty(modified) || modified
                obj.a = params(1);
                obj.b = params(2);
                obj.c = params(3);            
            end
            params = params(4:end);
        end
        
        %------------------------------------------------------------------
        % Generate testing values of parameters for cross validation
        function params = get_kernel_params(obj, pre_gram)
            % pre_gram is the matrix of scalar products distances 
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
            if obj.param_cv(3) == 1
                val_c = 2:5;
            else
                val_c = obj.c;
            end
            
            params = {(val_a)' (val_b)' (val_c)'};
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
            if obj.param_cv(3)
                obj.c = 2;
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
            gram = (obj.a * pre_gram + obj.b) .^ obj.c;
        end
    end

    methods (Static) %(Static, Access = protected)   
        %------------------------------------------------------------------
        % Modify the weight for concatenation
        function weight = weight_mod(weight)
            weight = weight * weight;
        end        
    end    
end

