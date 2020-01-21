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
        TestMeshX       % n x n matrix meshgrid of X testpoints
        TestMeshY       % n x n matrix meshgrid of Y testpoints
        TestMeans       % n rows output by model
        NormalizedTestMeans % n rows output by model normalized between 0 and 1
        TestS2          % n rows output by model
        TestFigure      % handle to visualization
        
        % Most recent centroid positions from weighted voronoi partition
        Centroids       % map<str(id), Position> of centroids of weighted voronoi partition
        CentroidsMatrix % simple nRobots x 2 matrix of x,y positions of centroids
        
        % Most recent circumcenter positions from weighted voronoi partition
        Circumcenters       % map<str(id), Position> of circumcenters of weighted voronoi partition
        CircumcentersMatrix % simple nRobots x 2 matrix of x,y circumcenters of centroids
        
        % Most recent uncertainty-maximizing positions from weighted voronoi partition
        MaxS2            % map<str(id), Position> of max uncertainty positions in weighted voronoi cells
        MaxS2Matrix      % simple nRobots x 2 matrix of x,y positions of max uncertainty points
        
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
            
            % generate test points with guard around perimeter to
            % aviod robot collisions
            pad = hilgpc_settings.EdgeGuard;
            [obj.TestMeshX, obj.TestMeshY] = meshgrid(...
                pad:hilgpc_settings.GridResolution:environment.XAxisSize-pad, ...
                pad:hilgpc_settings.GridResolution:environment.YAxisSize-pad);
            obj.TestPoints = reshape([obj.TestMeshX, obj.TestMeshY], [], 2);

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
            mesh(obj.TestMeshX, obj.TestMeshY, reshape(obj.TestMeans, size(obj.TestMeshX, 1), []));
            colormap(gray);
            
            % mesh upper and lower 95CI bounds
            lower_bound = obj.TestMeans - 2*sqrt(obj.TestS2);
            upper_bound = obj.TestMeans + 2*sqrt(obj.TestS2);
            mesh(obj.TestMeshX, obj.TestMeshY, reshape(lower_bound, size(obj.TestMeshX, 1), []),...
                'FaceColor', [0,1,1], 'EdgeColor', 'blue', 'FaceAlpha', 0.3);
            mesh(obj.TestMeshX, obj.TestMeshY, reshape(upper_bound, size(obj.TestMeshX, 1), []),...
                'FaceColor', [1,0.5,0], 'EdgeColor', 'red', 'FaceAlpha', 0.3);
        
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
        
        function NormalizeMeans(obj)
            % Normalizes the values in TestMeans to between 0 and 1 and
            % stores them in NormalizedTestMeans member variable.
            % Called as a helper function in ComputeCartogram and
            % ComputeCellMaxS2.
            
            f_minimum = min(obj.TestMeans);
            f_maximum = max(obj.TestMeans);
            obj.NormalizedTestMeans = (obj.TestMeans - f_minimum) ./ (f_maximum - f_minimum);
            
        end
        
        function cartogram = ComputeCartogram(obj)
           % Given TestPoints and TestMeans taken as the demand function,
           % returns TestPoints mapped to a space of uniform demand
           % density. Used as a helper function in ComputeCentroids and
           % ComputeCellMaxS2
           
           cartogram = zeros(size(obj.TestPoints));
            
            for i = 1:size(cartogram, 1)
                % get x and y point of this iteration
                xi = obj.TestPoints(i, 1);
                yi = obj.TestPoints(i, 2);
                
                % determine x shift
                %
                % fix yi and get all means from points left of this xi
                selection = and(obj.TestPoints(:,1) <= xi, obj.TestPoints(:,2) == yi);
                left_means = obj.NormalizedTestMeans(selection);
                
                % fix yi and get all means from points right of this xi
                selection = and(obj.TestPoints(:,1) >= xi, obj.TestPoints(:,2) == yi);
                right_means = obj.NormalizedTestMeans(selection);
                
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
                bottom_means = obj.NormalizedTestMeans(selection);
                
                % fix xi and get all means from points above of this yi
                selection = and(obj.TestPoints(:,2) >= yi, obj.TestPoints(:,1) == xi);
                top_means = obj.NormalizedTestMeans(selection);
                
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
                cartogram(i, 1:2) = [new_xi, new_yi];
            end
            
        end
        
        function ComputeCentroidsCartogram(obj)
            % Given TestPoints and TestMeans taken as the demand function,
            % computes weighted voronoi partition of field given robot
            % positions specified by environment. Positions and sets
            % Centroids member variable accordingly. Utilizes cartogram
            % mapping to determine voronoi partition and centroids in a
            % uniform space, then maps back to the original space
            
            % get current robot positions
            positions = obj.PositionsToMatrix();
            
            % Step 1: Normalize mean function prior to mapping to
            % uniform-density cartogram
            obj.NormalizeMeans();
            
            % Step 2: Map (x,y) points of field by diffeomorphism to
            % alternate field in which f is of uniform density using
            % cartogram helper function
            cartogram = obj.ComputeCartogram();
            
            % Visualize cartogram on auxiliary axes
            ax = obj.Plotter.AuxiliaryAxes;
            hold(ax, 'off');
            scatter(ax, cartogram(:,1), cartogram(:,2), 1, 'black', 'filled');
            
            % Step 3: Compute boundary / corners of cartogram mapping
            corner_indices = boundary(cartogram);
            corners = cartogram(corner_indices, :);
            
            % Visualize cartogram boundary on auxiliary axes
            hold(ax, 'on');
            scatter(ax, corners(:,1), corners(:,2), 5, 'red', 'filled');
            
            % Step 4: Compute voronoi centroids on cartogram mapping:
            % snap current positions to nearest neighbor in test points and
            % map to cartogrammed location of test point
            starting_indices = knnsearch(obj.TestPoints, positions);
            starting_positions = cartogram(starting_indices, :);
            px = starting_positions(:,1);
            py = starting_positions(:,2);
            
            numIterations = 1;    % only converge to centroids 1x in simulation
            [new_px, new_py] = Voronoi.LloydsAlgorithmCentroidsCartogram(px, py, corners, numIterations);
            cartogram_centroids = [new_px, new_py];
            
            % Visualize cartogram centroids
            scatter(ax, cartogram_centroids(:,1), cartogram_centroids(:,2), 10, 'red', 'filled');
            
            % Step 5: Invert mapping on centroids by taking the original
            % positions of the nearest neighbor of each centroid point
            % within the cartogram
            centroid_indices = knnsearch(cartogram, cartogram_centroids);
            centroids = obj.TestPoints(centroid_indices, :);
            
            % Visualize inverted centroids and original field boundary
            scatter(ax, centroids(:,1), centroids(:,2), 10, 'blue', 'filled');
            rect = polyshape([0, obj.Environment.XAxisSize, obj.Environment.XAxisSize, 0], [0, 0, obj.Environment.YAxisSize, obj.Environment.YAxisSize]); 
            plot(ax, rect, 'FaceAlpha', 0, 'EdgeColor', 'blue');
            
            % Rescale axes and set title
            title(ax, 'Exploit: Centroid Step');
            ax.DataAspectRatio = [1,1,1];
                        
            % Step 6: Set CentroidsMatrix and Centroids fields with helper
            % method
            obj.CentroidsMatrix = centroids;
            obj.Centroids = obj.MatrixToPositions(centroids);          
            
        end
        
        function ComputeCircumcenters(obj)
            % Given TestPoints and TestMeans taken as the demand function,
            % computes weighted voronoi partition of field given robot
            % positions specified by environment. Positions and sets
            % Circumcenters member variable accordingly. Utilizes cartogram
            % mapping to determine voronoi partition and circumcenters in a
            % uniform space, then maps back to the original space
            
            % get current robot positions
            positions = obj.PositionsToMatrix();
            
            % Step 1: Normalize mean function prior to mapping to
            % uniform-density cartogram
            obj.NormalizeMeans();
            
            % Step 2: Map (x,y) points of field by diffeomorphism to
            % alternate field in which f is of uniform density using
            % cartogram helper function
            cartogram = obj.ComputeCartogram();
            
            % Visualize cartogram on auxiliary axes
            ax = obj.Plotter.AuxiliaryAxes;
            hold(ax, 'off');
            scatter(ax, cartogram(:,1), cartogram(:,2), 1, 'black', 'filled');
            
            % Step 3: Compute boundary / corners of cartogram mapping
            corner_indices = boundary(cartogram);
            corners = cartogram(corner_indices, :);
            
            % Visualize cartogram boundary on auxiliary axes
            hold(ax, 'on');
            scatter(ax, corners(:,1), corners(:,2), 5, 'red', 'filled');
            
            % Step 4: Compute voronoi circumcenters on cartogram mapping:
            % snap current positions to nearest neighbor in test points and
            % map to cartogrammed location of test point
            starting_indices = knnsearch(obj.TestPoints, positions);
            starting_positions = cartogram(starting_indices, :);
            px = starting_positions(:,1);
            py = starting_positions(:,2);
            
            numIterations = 1;    % only converge to circumcenters 1x in simulation
            [new_px, new_py, radii] = Voronoi.LloydsAlgorithmCircumcenters(px, py, corners, numIterations);
            cartogram_circumcenters = [new_px, new_py];
            
            % Visualize cartogram circumcenters
            scatter(ax, cartogram_circumcenters(:,1), cartogram_circumcenters(:,2), 10, 'red', 'filled');
            
            % Plot bounding circles
            pos = [cartogram_circumcenters - radii, radii .* 2, radii.*2];
            for i = 1:size(radii, 1)
                rectangle(ax, 'Position',pos(i, :),'Curvature',[1 1]);
            end
                        
            % Step 5: Invert mapping on circumcenters by taking the original
            % positions of the nearest neighbor of each circumcenter point
            % within the cartogram
            circumcenter_indices = knnsearch(cartogram, cartogram_circumcenters);
            circumcenters = obj.TestPoints(circumcenter_indices, :);
            
            % Visualize inverted circumcenters and original field boundary
            scatter(ax, circumcenters(:,1), circumcenters(:,2), 10, 'blue', 'filled');
            rect = polyshape([0, obj.Environment.XAxisSize, obj.Environment.XAxisSize, 0], [0, 0, obj.Environment.YAxisSize, obj.Environment.YAxisSize]); 
            plot(ax, rect, 'FaceAlpha', 0, 'EdgeColor', 'blue');
            
            % Rescale axes and set title
            title(ax, 'Exploit: Circumcenter Step');
            ax.DataAspectRatio = [1,1,1];
                        
            % Step 6: Set CentroidsMatrix and Centroids fields with helper
            % method
            obj.CircumcentersMatrix = circumcenters;
            obj.Circumcenters = obj.MatrixToPositions(circumcenters);          
            
        end
        
        function ComputeCentroidsNumerically(obj)
            % Given TestPoints and TestMeans taken as the demand function,
            % computes weighted voronoi partition of field given robot
            % positions specified by environment. Positions and sets
            % Centroids member variable accordingly. Utilizes numerical
            % integration to compute centroids of a voronoi partition in
            % the original space.
            
            % get current robot positions
            positions = obj.PositionsToMatrix();
            
            % Step 1: Normalize mean function prior to computing centroids
            obj.NormalizeMeans();
            
            % Step 2: Compute voronoi centroids in original space using
            % numerical integration of f
            px = positions(:,1);
            py = positions(:,2);
            corners = [min(obj.TestPoints(:,1)), min(obj.TestPoints(:,2));
                max(obj.TestPoints(:,1)), min(obj.TestPoints(:,2));
                max(obj.TestPoints(:,1)), max(obj.TestPoints(:,2));
                min(obj.TestPoints(:,1)), max(obj.TestPoints(:,2))];
            tx = obj.TestPoints(:,1);
            ty = obj.TestPoints(:,2);
            f_samples = obj.NormalizedTestMeans;
            
            [new_px, new_py, polygons] = Voronoi.LloydsAlgorithmCentroidsNumerically(...
                px, py, corners, tx, ty, f_samples);
            centroids = [new_px, new_py];

            % Visualize Voronoi partitions and centroids
            ax = obj.Plotter.AuxiliaryAxes;
            cla(ax);
            hold(ax, 'on');
            
            for i = 1:obj.Environment.NumRobots
                pgon = polygons{i,1};
                plot(ax, polyshape(pgon(:,1), pgon(:,2)));
            end
            scatter(ax, centroids(:,1), centroids(:,2), 10, 'black', 'filled');
            
            % Rescale axes and set title
            title(ax, 'Exploit: Centroid Step');
            ax.DataAspectRatio = [1,1,1];
                        
            % Step 6: Set CentroidsMatrix and Centroids fields with helper
            % method
            obj.CentroidsMatrix = centroids;
            obj.Centroids = obj.MatrixToPositions(centroids);          
            
        end
        
        function ComputeCellMaxS2(obj)
            % Given TestPoints, TestMeans, and TestSD taken as the demand function,
            % computes weighted voronoi partition of field given robot
            % positions specified by environment.Positions, then finds
            % uncertainty-maximizing point within each cell, and sets MaxS2
            % member variable accordingly
            
            % get current robot positions
            positions = obj.PositionsToMatrix();
            
            % Step 1: Normalize mean function prior to mapping to
            % uniform-density cartogram
            obj.NormalizeMeans();
            
            % Step 2: Map (x,y) points of field by diffeomorphism to
            % alternate field in which f is of uniform density using
            % cartogram helper function
            cartogram = obj.ComputeCartogram();
            
            % Visualize cartogram on auxiliary axes
            ax = obj.Plotter.AuxiliaryAxes;
            hold(ax, 'off');
            scatter(ax, cartogram(:,1), cartogram(:,2), 1, 'black', 'filled');
            
            % Step 3: Compute boundary / corners of cartogram mapping
            corner_indices = boundary(cartogram);
            corners = cartogram(corner_indices, :);
            
            % Visualize cartogram boundary on auxiliary axes
            hold(ax, 'on');
            scatter(ax, corners(:,1), corners(:,2), 5, 'red', 'filled');
            
            % Step 4: Compute voronoi partitions on cartogram mapping:
            % snap current positions to nearest neighbor in test points and
            % map to cartogrammed location of test point
            starting_indices = knnsearch(obj.TestPoints, positions);
            starting_positions = cartogram(starting_indices, :);
            px = starting_positions(:,1);
            py = starting_positions(:,2);
            
            [vertices, cells] = Voronoi.VoronoiBounded(px, py, corners);
            
            % Step 5: Find uncertainty-maximizing points in each
            % voronoi partition in the cartogram space and determine
            % corresponding point in original space to be sampled
            
            max_s2_points = zeros(obj.Environment.NumRobots, 2);
            
            % visualizations for debugging
            figure;
            hold on;
            
            for i = 1:obj.Environment.NumRobots
                
                % iterate through each voronoi cell polygon and find
                % uncertainty-maximizing points
                cell = cells{i};
                polygon = vertices(cell, :); % subset the vertices of the polygon bounding just this cell
                
                % get indices of points in this voronoi cell polygon
                in_indices = inpolygon(cartogram(:,1), cartogram(:,2), polygon(:,1), polygon(:,2));
                
                % get actual points in cartogram and original space at
                % these indices
                in_points_cartogram = cartogram(in_indices, :);
                in_points_original = obj.TestPoints(in_indices, :)
                
                % get uncertainties of points in this voronoi cell polygon
                in_s2 = obj.TestS2(in_indices, :);
                
                % find max uncertainty of this voronoi cell polygon
                [max_s2, max_s2_index] = max(in_s2);
                
                % store coordinates of this uncertainty-maximizing point
                % for this cell in the original, non-uniform space
                max_s2_point_cartogram = in_points_cartogram(max_s2_index,:);
                max_s2_point_original = in_points_original(max_s2_index,:);
                max_s2_points(i, :) = max_s2_point_original;
               
                
                
                % Visualizations for debugging - MOVE
                pshape = polyshape(polygon(:,1), polygon(:,2));
                in_points = cartogram(in_indices, :);
                in_original_points = obj.TestPoints(in_indices, :);
                color = obj.Plotter.RobotColors(i,:)
                dark_color = [0 0 0];
                size = obj.Plotter.DotSize;
                
                plot(pshape, 'FaceColor', color);
%                 hold on;
%                 scatter(in_points(:,1), in_points(:,2), size, color);
                scatter(in_original_points(:,1), in_original_points(:,2), size, color);
%                 scatter(max_s2_point_cartogram(:,1), max_s2_point_cartogram(:,2), size, dark_color);
%                 scatter(max_s2_point_original(:,1), max_s2_point_original(:,2), size, dark_color);
%                 hold off;
            end
            
            % Rescale axes and set title
            title(ax, 'Explore: MaxS2 Step');
            ax.DataAspectRatio = [1,1,1];
            
            % Visualize inverted max s2 points and original field boundary
            scatter(ax, max_s2_points(:,1), max_s2_points(:,2), 10, 'blue', 'filled');
            rect = polyshape([0, obj.Environment.XAxisSize, obj.Environment.XAxisSize, 0], [0, 0, obj.Environment.YAxisSize, obj.Environment.YAxisSize]); 
            plot(ax, rect, 'FaceAlpha', 0, 'EdgeColor', 'blue');

            % Step 6: Set MaxS2Matrix and MaxS2 fields with helper
            % method
            obj.MaxS2Matrix = max_s2_points;
            obj.MaxS2 = obj.MatrixToPositions(max_s2_points);  
            
            
            
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

