classdef ClusteringAPI < handle    
    properties
        num_clusters       % Number of clusters
    end
    
    methods
        %------------------------------------------------------------------
        % Set the cluster number
        function set_cluster_number(obj, N)
            obj.num_clusters = N;
        end
        
        %------------------------------------------------------------------
        % Clusterize the observations X (one per line)
        % file is optionnal: indicate where to cache the clusters
        clusters = clusterize(obj, X, file)
        
        %------------------------------------------------------------------
        % Assign the observations X to a cluster (one per line)
        idCluster = assign(obj, clusters, X)               
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = toString(obj)
        str = toFileName(obj)
        str = toName(obj)                
    end    
end

