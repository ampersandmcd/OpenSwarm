classdef HILGPC_Planner < handle
    %HILGPC_PLANNER 
    %   Class to facilitate planning of sampling routes
    
    properties
        % Dependencies
        Environment     % OpenSwarm environment object
        Settings        % HILGPC_Settings dependency
        Data            % HILGPC_Data dependency
        
        % Data Members
        ToursByRobot    % cell array of computed TSP tours by robot: index {i} contains the tour for robot i
        ToursByStop     % cell array of computed TSP tours by stop: index {i} contains the ith stop for each robot
        TourFigure      % figure to display TSP tour
        
        % Plotting Specs
        XLabelOffset;       % x-offset distance for labels on plots
        YLabelOffset;       % y-offset distance for labels on plots
        
    end
    
    methods
        function obj = HILGPC_Planner(environment, settings, data)
            obj.Environment = environment;
            obj.Settings = settings;
            obj.Data = data;
            
            obj.XLabelOffset = 15;
            obj.YLabelOffset = 15;
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
        
        function target_queue = ClusterTSPTour(obj)
            % Given Data.SamplePoints needed to be sampled, cluster them
            % into k = Environment.NumRobots clusters.
            % For each cluster, arrange points in a TSP route to minimize
            % distance traveled.
            % Finally, return a TargetQueue = cell(map<id, position>) where
            % entry i of the cell array is a map containing the ith
            % position for each robot with id = j.
            % If lengths of paths differ for robots, set final positions
            % for robots constant.
            
            points = obj.Data.SamplePoints;
            
            % kmeans cluster the points to tour
            k_index = kmeans(points, obj.Environment.NumRobots);
            
            % initialize cell array to store the point-tour matrix for
            % robot i in cell{i}
            tsp_tours = cell(obj.Environment.NumRobots, 1);
            
            % track longest tour
            longest_tour = 0;
            
            for i = 1:obj.Environment.NumRobots
               % construct TSP tour for each cluster / each robot
               
               % subset points for robot i
               tour_points = points(i == k_index, 1:2);
               
               % solve TSP tour
               tsp_config.xy = tour_points;
               tsp_config.showProg = false;
               tsp_config.showResult = true;
               tsp_config.numIter = 100;
               tsp_config.axisLimits = [0, obj.Environment.XAxisSize, 0, obj.Environment.YAxisSize];
               tsp_struct = tsp_ga(tsp_config);
               tsp_route = tsp_struct.optRoute;
               
               % reorder points by TSP index
               tsp_tour = tour_points(tsp_route, 1:2);
               
               % find start point of tour closest to center of field
               x = tsp_tour(:,1);
               x_mid = obj.Environment.XAxisSize / 2;
               y = tsp_tour(:,2);
               y_mid = obj.Environment.YAxisSize / 2;
               start_distances = (x - x_mid) .^ 2 + (y - y_mid) .^ 2;
               
               [~, start_idx] = min(start_distances);
               
               % rotate tour stops to begin at start point
               tsp_tour = circshift(tsp_tour, size(tsp_tour,1) - start_idx + 1);
               
               % save robot i's tour in cell array
               tsp_tours{i} = tsp_tour;
               
               % update longest tour
               if size(tsp_tour, 1) > longest_tour
                   longest_tour = size(tsp_tour, 1);
               end
            end
            
            % save for plotting
            obj.ToursByRobot = tsp_tours;
            
            
            % rearrange tours to be by stop in order to return target_queue
            
            % initialize cell array to store the by stop representation of
            % the tour: stop {i} of all j robots is in index {i}
            by_stop = cell(longest_tour, 1);
            
            for i = 1:longest_tour
                % store ith stop of robot j in row j of stop_i
                stop_i = zeros(obj.Environment.NumRobots, 2);
                
                for j = 1:obj.Environment.NumRobots
                    % copy stop i of robot j into stop_i(robot_j)
                    
                    % get jth robot's tour
                    tour = tsp_tours{j};
                    
                    % get stop i or final stop
                    stop_index = min(i, size(tour, 1));
                    stop = tour(stop_index, 1:2);
                    
                    stop_i(j, 1:2) = stop;
                end
                
                % save stop_i into ith cell of by_stop
                by_stop{i} = stop_i;
            end
            
            % save for plotting
            obj.ToursByStop = by_stop;
            
            % construct and return target queue
            
            target_queue = cell(longest_tour, 1);
            
            for i = 1:longest_tour
                % construct and return target queue
                
                targets = by_stop{i}; 
                target_map = containers.Map;
                
                for j = 1:size(targets, 1)
                    % add NumRobots targets to map of stop i in queue
                    target_x = targets(j, 1);
                    target_y = targets(j, 2);
                    target_pos = Position.TargetPosition(target_x, target_y);
                    target_map(num2str(j)) = target_pos;                    
                end
                
                % add map of stop i into queue
                target_queue{i} = target_map;
                
            end
            
            % return          
            
        end
        
        function VisualizeTour(obj)
            % Visualize the TSP tour computed and stored in ToursByRobot
            
            if isempty(obj.TourFigure)
                obj.TourFigure = figure;
            end
            
            ax = obj.TourFigure.CurrentAxes;
            cla(ax);
            axes(ax);
            hold on;
            colors = lines(obj.Environment.NumRobots);
            
            for i = 1:size(obj.ToursByRobot, 1)
                % plot inorder tour of each robot in different color
                
                tour = obj.ToursByRobot{i};
                
                x = tour(:,1);
                y = tour(:,2);
                c = colors(i, :);
                labels = string(1:size(tour,1));
                
                plot(x', y', '-o', 'Color', c, 'MarkerEdgeColor', c, 'MarkerFaceColor', c);
                text(x + obj.XLabelOffset, y + obj.YLabelOffset, labels, 'Color', c); 
                
            end
            
            title(sprintf("TSP Sampling Tours for %d Robots", obj.Environment.NumRobots));
            axis([0, obj.Environment.XAxisSize, 0, obj.Environment.YAxisSize]);
            
        end
    end
end

