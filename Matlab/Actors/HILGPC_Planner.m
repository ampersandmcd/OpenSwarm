classdef HILGPC_Planner
    %HILGPC_PLANNER 
    %   Class to facilitate planning of sampling routes
    
    properties
        % Dependencies
        Environment     % OpenSwarm environment object
        Settings        % HILGPC_Settings dependency
        Data            % HILGPC_Data dependency
        
        % Data Members
        
    end
    
    methods
        function obj = HILGPC_Planner(environment, settings, data)
            obj.Environment = environment;
            obj.Settings = settings;
            obj.Data = data;
        end
        
        function ReduceUncertainty(obj)
            % Determine and update Data.SamplePoints to contain points
            % necessary to sample to reduce max s2 beneath s2_threshold
            
            [max_s2, max_index] = max(obj.Data.TestS2);
            
            while max_s2 > obj.Settings.S2Threshold                
                % iteratively add points to sample and recompute GP
                
                % get (x,y) of max uncertainty point then add to sample
                % points and train points list
                point_to_sample = obj.Data.TestPoints(max_index, 1:2);
                obj.Data.SamplePoints = cat(1, obj.Data.SamplePoints, point_to_sample);
                obj.Data.TrainPoints = cat(1, obj.Data.TrainPoints, point_to_sample);
                
                % output message on each iteration
                sprintf("Max S2 = %f\t\tSample Point = (%d, %d)", max_s2, point_to_sample(1), point_to_sample(2)) 
                
                % assume point takes mean value and add this to SampleMeans
                % and TrainMeans
                mean_of_sample = obj.Data.TestMeans(max_index);
                obj.Data.SampleMeans = cat(1, obj.Data.SampleMeans, mean_of_sample);
                obj.Data.TrainMeans = cat(1, obj.Data.TrainMeans, mean_of_sample);
                
                % given extra training data, recompute GP and max s2
                obj.Data.ComputeGP();
                [max_s2, max_index] = max(obj.Data.TestS2);
            end
            
            sprintf("\nFinished Planning: Max S2 = %d < Threshold S2 = %d", max_s2, obj.Settings.S2Threshold) 
                        
        end
        
        function ClusterTSPTour(obj)
            % Given Data.SamplePoints needed to be sampled, cluster them
            % into k = Environment.NumRobots clusters.
            % For each cluster, arrange points in a TSP route to minimize
            % distance traveled.
            % Finally, return a TargetQueue = cell(map<id, position>) where
            % entry i of the cell array is a map containing the ith
            % position for each robot with id = j.
            % If lengths of paths differ for robots, set final positions
            % for robots constant.
            
            disp("Not Yet Implemented");
            
        end
    end
end

