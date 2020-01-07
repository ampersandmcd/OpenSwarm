classdef HILGPC_Data < handle
    %HILGPC_DATA
    %   Object to serve as a data payload throughout the HILGPC project,
    %   carrying human-input data, machine-sampled data, combined data
    %   used to train GP model, test data to predict with GP model, and
    %   hyperparameters of the GP model
    
    properties
        % Dependencies
        Environment     % OpenSwarm environment object
        Settings        % HILGPC_Settings dependency
        Plotter         % Plotting dependency
        
        % Human-input data
        InputPoints     % n rows by 2 col of human-input (x,y) points
        InputMeans      % n rows by 1 col of human-input means
        InputS2         % n rows by 1 col of human-input variances
        InputConfidence % human-input confidence in measurements
        
        % Machine-sampled data
        SamplePoints    % n rows by 2 col of machine-sampled (x,y) points
        SampleMeans     % n rows by 1 col of machine-sampled means
        SampleS2        % n rows by 1 col of machine-sampled variances
        
        % Human-Machine combined data
        TrainPoints     % concatenation of InputPoints and SamplePoints
        TrainMeans      % concatenation of InputMeans and SampleMeans
        TrainS2         % concatenation of InputS2 and SampleS2
        
        % Predicted data (used to visualize the GP)
        TestPoints      % n rows by 2 col of (x,y) points to evaluate model
        TestMeans       % n rows output by model
        TestS2          % n rows output by model
        TestFigure      % handle to visualization
        
        % Most recent centroid positions from weighted voronoi partition
        Centroids       % map<str(id), Position> of centroids of weighted voronoi partition
        CentroidsMatrix % simple nRobots x 2 matrix of x,y positions of centroids
        
        % Most recent uncertainty-maximizing positions from weighted voronoi partition
        MaxU            % map<str(id), Position> of MaxU positions in weighted voronoi cells
        MaxUMatrix      % simple nRobots x 2 matrix of x,y positions of MaxU points
        
        % Other relevant GP data
        Hyp             % hyperparameters of GP model
    end
    
    methods
        function obj = HILGPC_Data(environment, plotter, hilgpc_settings)
            % HILGPC_DATA
            %    Set environment dependency and generate test points
            
            % set dependencies
            obj.Environment = environment;
            obj.Plotter = plotter;
            obj.Settings = hilgpc_settings;
            
            % generate test points
            [plotX, plotY] = meshgrid(0:hilgpc_settings.GridResolution:environment.XAxisSize, ...
                                        0:hilgpc_settings.GridResolution:environment.YAxisSize);
            obj.TestPoints = reshape([plotX, plotY], [], 2);

            % configure GP hyperparameters
            ell = 100;
            sf = 1;
            hyp.cov = log([ell; sf]);
            hyp.mean = [];
            sn = 1;
            hyp.lik = log(sn);            
            obj.Hyp = hyp;
            
            % if reusing user input, load data
            if obj.Settings.RecycleHumanPrior
                obj.RecycleHumanPrior();
            end
            
        end
        
        function obj = GetHumanPrior(obj)
            % GETHumanPRIOR
            %   Take human input for estimations of mean and s2 to
            %   initialize the prior for GP estimation
            
            h = obj.GetInputGUI();
            inputs = {};            % temp cell array to store input points as Point objects before casting to vector
            num_points = 0;
            
            while ishandle(h)
                try
                    % get input point
                    [x, y] = ginput(1);
                    point = Point(x, y);

                    is_new_point = true;
                    % if point is close to a preexisting point, increment
                    % its count
                    for i = 1:size(inputs, 1)
                       other_point = inputs{i, 1};
                       if point.Distance(other_point) < obj.Settings.DistanceThreshold
                          % increment count of other point in temp_input cell array
                          inputs{i, 2} = mod((inputs{i, 2} + 1), obj.Settings.MaxClicks+1);
                          is_new_point = false;
                          break;
                       end
                    end

                    % add new point to temp_inputs if point is new
                    if is_new_point
                        inputs{num_points + 1, 1} = point;
                        inputs{num_points + 1, 2} = 0; % initialize to 0 = no information
                        num_points = num_points + 1;
                    end

                    % visualize input points
                    obj.ScatterInputs(inputs);
                catch
                    % catch error when user clicks done box
                end
            end
            
            
            % get user input confidence
            confidence = inputdlg('Enter confidence in your measurements as a decimal between 0 and 1');
            obj.InputConfidence = str2double(confidence{1});
                        
            
            % done with input -> convert inputs into [x,y] array and store
            % into InputPoints, InputMeans, TrainPoints and TrainMeans
            
            % (note: do not include last point, as it is from clicking
            % done button)
            for i = 1:size(inputs, 1)-1
                % store input point
                point = inputs{i, 1};
                [x,y] = point.ToPair();
                
                obj.InputPoints(i, 1:2) = [x,y];
                
                % store input mean
                obj.InputMeans(i, 1) = inputs{i, 2};
            end
            
            
            % add 2 points to the training set each offset by one stddev 
            % to properly train model mean and variance given imperfect
            % human input

            % compute uncertainty
            uncertainty = 1 - obj.InputConfidence;
            
            % iterate through input means and shift up and down to
            % upper/lower uncertainty bounds to create train means
            for i = 1:size(obj.InputPoints, 1)
                
                % compute upper and lower bounds
                mean = obj.InputMeans(i, 1);
                shift = uncertainty * mean;
                upper = mean + shift;
                lower = mean - shift;
                
                % create lower bound train point on odd indices
                obj.TrainPoints(2*i-1, 1:2) = obj.InputPoints(i, 1:2);
                obj.TrainMeans(2*i-1, 1) = lower;
                
                % create upper bound train point on even indices
                obj.TrainPoints(2*i, 1:2) = obj.InputPoints(i, 1:2);
                obj.TrainMeans(2*i, 1) = upper;
                
            end
                 
        end
        
        function h = GetInputGUI(obj)
            
            % create UI for prior mean input by user
            fig = figure('units', 'normalized');
            h = uicontrol(fig, 'Style', 'PushButton', ...
                'String', 'Done', ...
                'Callback', 'close(gcbf)');
            
            % configure axes
            ax = axes('Position', [0.1, 0.2, 0.8, 0.7]);
            xlim([0, obj.Environment.XAxisSize]);
            ylim([0, obj.Environment.YAxisSize]);
            
            % configure aesthetics
            title(sprintf("Click to indicate function mean on testbed from\n " ...
                + "scale of 0-%d, where\n 0 = darkest and " ...
                + "%d = brightest", obj.Settings.MaxClicks, obj.Settings.MaxClicks));
            box on;
            daspect([1,1,1]);
            colormap(jet);
            colorbar;
            ax.CLim = [0, obj.Settings.MaxClicks];

        end
        
        function ScatterInputs(obj, inputs)
            ax = gca();
            cla(ax);
            hold on;
            
            for i = 1:size(inputs, 1)
                point = inputs{i, 1};
                [x,y] = point.ToPair();
                level = inputs{i, 2};
                
                scatter(ax, x, y, 50, level, 'filled');
            end
        end
        
        function obj = ComputeGP(obj)
            
            % optimize hyperparameters
            obj.Hyp = minimize(obj.Hyp, @gp, -obj.Settings.MaxEvals, @infGaussLik, obj.Settings.MeanFunction,...
                obj.Settings.CovFunction, obj.Settings.LikFunction, obj.TrainPoints, obj.TrainMeans);
            
            % compute on testpoints
            [m, s2] = gp(obj.Hyp, @infGaussLik, obj.Settings.MeanFunction,...
                obj.Settings.CovFunction, obj.Settings.LikFunction, ...
                obj.TrainPoints, obj.TrainMeans, obj.TestPoints);
            
            % save testpoint means and s2
            obj.TestMeans = m;
            obj.TestS2 = s2;
            
        end
        
        function u = GetMaxUncertainty(obj)
            
            % return maximum uncertainty point in entire field
            u = max(obj.TestS2);
            
        end
        
        function obj = VisualizeGP(obj)
            
            if isempty(obj.TestFigure)
                obj.TestFigure = figure;
            end
            
            ax = obj.TestFigure.CurrentAxes;
            cla(ax);
            axes(ax);
            hold on;
            
            % scatter ground truth from human
            scatter3(obj.InputPoints(:,1) , obj.InputPoints(:,2), obj.InputMeans, 'black', 'filled');
            
            % scatter Gaussian-shifted training points based on ground
            % truth of human
            scatter3(obj.TrainPoints(:,1) , obj.TrainPoints(:,2), obj.TrainMeans(:,1), 'magenta', 'filled');
            
            % scatter points-to-sample in blue
            if size(obj.SamplePoints, 1) > 0
                scatter3(obj.SamplePoints(:,1) , obj.SamplePoints(:,2), obj.SampleMeans(:,1), 'blue', 'filled');
                legend_text = ["Human-input ground truth", ...
                "Gaussian-shifted train points to account for confidence", ...
                "Points to sample", "Mean", "Lower CI-95", "Upper CI-95"];
            else
                legend_text = ["Human-input ground truth", ...
                "Gaussian-shifted train points to account for confidence", ...
                "Mean", "Lower CI-95", "Upper CI-95"];
            end
            
            % mesh GP surface
            [plotX, plotY] = meshgrid(0:obj.Settings.GridResolution:obj.Environment.XAxisSize, ...
                                        0:obj.Settings.GridResolution:obj.Environment.YAxisSize);
            mesh(plotX, plotY, reshape(obj.TestMeans, size(plotX, 1), []));
            colormap(gray);
            
            % mesh upper and lower 95CI bounds
            lower_bound = obj.TestMeans - 2*sqrt(obj.TestS2);
            upper_bound = obj.TestMeans + 2*sqrt(obj.TestS2);
            mesh(plotX, plotY, reshape(lower_bound, size(plotX, 1), []), 'FaceColor', [0,1,1], 'EdgeColor', 'blue', 'FaceAlpha', 0.3);
            mesh(plotX, plotY, reshape(upper_bound, size(plotX, 1), []), 'FaceColor', [1,0.5,0], 'EdgeColor', 'red', 'FaceAlpha', 0.3);
        
            title(sprintf("Estimated Function with Sample Points\n(s2 threshold = %f)", obj.Settings.S2Threshold));
            legend(legend_text, 'Location', 'Northeast');
            
            view(3)
        end
        
        function RecycleHumanPrior(obj)
            
            prior = readtable(obj.Settings.RecycleFilename);
            
            % save first two columns of (x,y) points without header row
            obj.InputPoints = prior{1:end, 1:2};
            
            % save third column of means without header row
            obj.InputMeans = prior{1:end, 3};
            
            % save user confidence in fourth column without header row
            obj.InputConfidence = prior{1, 4};
            
            % build test set
            
            % add 2 points to the training set each offset by one stddev
            % to properly train model mean and variance given imperfect
            % human input
            
            % compute uncertainty
            uncertainty = 1 - obj.InputConfidence;
            
            % iterate through input means and shift up and down to
            % upper/lower uncertainty bounds to create train means
            for i = 1:size(obj.InputPoints, 1)
                
                % compute upper and lower bounds
                mean = obj.InputMeans(i, 1);
                shift = uncertainty * mean;
                upper = mean + shift;
                lower = mean - shift;
                
                % create lower bound train point on odd indices
                obj.TrainPoints(2*i-1, 1:2) = obj.InputPoints(i, 1:2);
                obj.TrainMeans(2*i-1, 1) = lower;
                
                % create upper bound train point on even indices
                obj.TrainPoints(2*i, 1:2) = obj.InputPoints(i, 1:2);
                obj.TrainMeans(2*i, 1) = upper;
                
            end
            
        end
        
        function SaveHumanPrior(obj, filename)
            
            prior = cat(2, obj.InputPoints, obj.InputMeans);
            prior(1, 4) = obj.InputConfidence;
            
            file = fopen(filename, 'w');
            fprintf(file, "X,Y,Means,Confidence\n");
            fclose(file);
            
            dlmwrite(filename, prior, '-append');
            
        end
        
        function ComputeCentroids(obj)
            % test helper methods
            %positions = obj.PositionsToMatrix();
            %map = obj.MatrixToPositions(positions);
            % Given TestPoints and TestMeans taken as the demand function,
            % computes weighted voronoi partition of field given robot
            % positions specified by environment. Positions and sets
            % Centroids member variable accordingly
            
            % FOR TESTING
            % positions = [0,0;1000,0;500,700];
            
            % get current robot positions
            positions = obj.PositionsToMatrix;
            
            % Step 1: Normalize mean function prior to mapping to
            % uniform-density cartogram
            f_minimum = min(obj.TestMeans);
            f_maximum = max(obj.TestMeans);
            f_normalized = (obj.TestMeans - f_minimum) ./ (f_maximum - f_minimum);
            
            % Step 2: Map (x,y) points of field by diffeomorphism to
            % alternate field in which f is of uniform density using a
            % cartogram
            cartogram_points = zeros(size(obj.TestPoints));
            
            for i = 1:size(cartogram_points, 1)
                % get x and y point of this iteration
                xi = obj.TestPoints(i, 1);
                yi = obj.TestPoints(i, 2);
                
                % determine x shift
                %
                % fix yi and get all means from points left of this xi
                selection = and(obj.TestPoints(:,1) <= xi, obj.TestPoints(:,2) == yi);
                left_means = f_normalized(selection);
                
                % fix yi and get all means from points right of this xi
                selection = and(obj.TestPoints(:,1) >= xi, obj.TestPoints(:,2) == yi);
                right_means = f_normalized(selection);
                
                % compute x shift by taking numerical integral under the
                % one dimensional conditional distribution along xi for 
                % fixed yi and comparing integral left of xi to right of xi
                %
                % if integral left of xi is greater, shift point right
                % if integral right of xi is greater, shift point left
                % overall, this will "flatten" the distribution
                left_integral = simpsons(left_means, 0, xi, []);    % integrate 0 -> xi
                right_integral = simpsons(right_means, xi, obj.Environment.XAxisSize, []); % integrate xi -> max_x
                x_shift = left_integral - right_integral;
                
                %%%%%%                
                
                % determine y shift
                %
                % fix xi and get all means from points below this yi
                selection = and(obj.TestPoints(:,2) <= yi, obj.TestPoints(:,1) == xi);
                bottom_means = f_normalized(selection);
                
                % fix xi and get all means from points above of this yi
                selection = and(obj.TestPoints(:,2) >= yi, obj.TestPoints(:,1) == xi);
                top_means = f_normalized(selection);
                
                % compute y shift by taking numerical integral under the
                % one dimensional conditional distribution along yi for 
                % fixed xi and comparing integral above yi to below yi
                %
                % if integral below yi is greater, shift point up
                % if integral above yi is greater, shift point down
                % overall, this will "flatten" the distribution
                bottom_integral = simpsons(bottom_means, 0, yi, []);    % integrate 0 -> yi
                top_integral = simpsons(top_means, yi, obj.Environment.YAxisSize, []); % integrate yi -> max_y
                y_shift = bottom_integral - top_integral;
                
                %%%%%%
                
                % assign shifted points to cartogram_points
                new_xi = xi + x_shift;
                new_yi = yi + y_shift;
                cartogram_points(i, 1:2) = [new_xi, new_yi];
            end
            
            % Visualize cartogram on auxiliary axes
            ax = obj.Plotter.AuxiliaryAxes;
            hold(ax, 'off');
            scatter(ax, cartogram_points(:,1), cartogram_points(:,2), 1, 'black', 'filled');
            
            % Step 3: Compute boundary / corners of cartogram mapping
            corner_indices = boundary(cartogram_points);
            corners = cartogram_points(corner_indices, :);
            
            % Visualize cartogram boundary on auxiliary axes
            hold(ax, 'on');
            scatter(ax, corners(:,1), corners(:,2), 5, 'red', 'filled');
            
            % Step 4: Compute voronoi centroids on cartogram mapping:
            % snap current positions to nearest neighbor in test points and
            % map to cartogrammed location of test point
            starting_indices = knnsearch(obj.TestPoints, positions);
            starting_positions = cartogram_points(starting_indices, :);
            px = starting_positions(:,1);
            py = starting_positions(:,2);
            
            numIterations = 1;    % only converge to centroids 1x in simulation
            visualize = false;
            [new_px, new_py] = LloydsAlgorithm(px, py, corners, numIterations, visualize);
            cartogram_centroids = [new_px, new_py];
            
            % Visualize cartogram centroids
            scatter(ax, cartogram_centroids(:,1), cartogram_centroids(:,2), 10, 'red', 'filled');
            
            % Step 5: Invert mapping on centroids by taking the original
            % positions of the nearest neighbor of each centroid point
            % within the cartogram
            centroid_indices = knnsearch(cartogram_points, cartogram_centroids);
            centroids = obj.TestPoints(centroid_indices, :);
            
            % Visualize inverted centroids and original field boundary
            scatter(ax, centroids(:,1), centroids(:,2), 10, 'blue', 'filled');
            rect = polyshape([0, obj.Environment.XAxisSize, obj.Environment.XAxisSize, 0], [0, 0, obj.Environment.YAxisSize, obj.Environment.YAxisSize]); 
            plot(ax, rect, 'FaceAlpha', 0, 'EdgeColor', 'blue');
            
            % Rescale axes and set title
            title(ax, 'Cartogram');
            ax.DataAspectRatio = [1,1,1];
            
            
            % Step 6: Set CentroidsMatrix and Centroids fields with helper
            % method
            obj.CentroidsMatrix = centroids;
            obj.Centroids = obj.MatrixToPositions(centroids);          
            
        end
        
        function ComputeCellMaxU(obj)
            % test helper methods
            positions = obj.PositionsToMatrix();
            map = obj.MatrixToPositions(positions);
            % Given TestPoints, TestMeans, and TestSD taken as the demand function,
            % computes weighted voronoi partition of field given robot
            % positions specified by environment.Positions, then finds
            % uncertainty-maximizing point within each cell, and sets MaxU
            % member variable accordingly
        end
       
        function mat = PositionsToMatrix(obj)
           % Helper function to convert environment.Positions map to a simple
           % nRobots x 2 matrix of x,y positions
           
           mat = zeros(obj.Environment.NumRobots, 2);
           map = obj.Environment.Positions;
           
           for i = 1:obj.Environment.NumRobots
               position = map(num2str(i));
               x = position.Center.X;
               y = position.Center.Y;
               mat(i, 1:2) = [x,y];
           end
           
           % returns simple nRobots x 2 matrix of x_i,y_i in ith row           
           
        end
        
        function map = MatrixToPositions(obj, mat)
           % Helper function to convert a simple nRobots x 2 matrix of 
           % x,y positions to a map
           
           map = containers.Map;
           
           for i = 1:obj.Environment.NumRobots
               x = mat(i, 1);
               y = mat(i, 2);
               position = Position.TargetPosition(x, y);
               map(num2str(i)) = position;
           end
           
           % returns map<str(id), Position> from xy matrix
           
        end
    end
end

