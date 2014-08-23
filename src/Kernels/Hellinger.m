classdef Hellinger < KernelAPI
    
    methods        
        %------------------------------------------------------------------
        % Constructor
        function obj = Hellinger(signatures, sigs_weights)
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
            str = 'Hellinger kernel';
        end
        function str = kernelToFileName(obj)
            str = 'Hel';
        end
        function str = kernelToName(obj)
            str = 'Hel';
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
            sigs1 = sqrt(sigs1);
            sigs2 = sqrt(sigs2);
            if nargin<3
                pre_gram = sigs1' * sigs1;
            else
                pre_gram = sigs1' * sigs2;
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
            weight = weight * weight;
        end        
    end
end

