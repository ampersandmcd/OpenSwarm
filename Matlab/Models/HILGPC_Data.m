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
        
        % Human-input data (low-fidelity)
        InputPoints     % n rows by 2 col of human-input (x,y) points
        InputMeans      % n rows by 1 col of human-input means
        InputS2         % n rows by 1 col of human-input variances
        InputConfidence % human-input lofi confidence in measurements
        
        % Machine-sampled data (high-fidelity)
        SampleIds       % n rows by 1 col of machine-sampled point robot ids
        SamplePoints    % n rows by 2 col of machine-sampled (x,y) points
        SampleMeans     % n rows by 1 col of machine-sampled means
        SampleS2        % n rows by 1 col of machine-sampled variances
        SampleConfidence % sample-input lofi confidence in measurements
        NumSamples      % how many samples have been collected
        
        % Human-Train data (low-fidelity)
        LofiTrainPoints     % InputPoints doubled up for training
        LofiTrainMeans      % InputMeans doubled up for training
        LofiTrainS2         % InputS2 doubled up for training
        NumLofi
        
        % Machine-train data (high-fidelity)
        HifiTrainPoints     % SamplePoints doubled up for training
        HifiTrainMeans      % SampleMeans doubled up for training
        HifiTrainS2         % SampleS2 doubled up for training
        NumHifi
        
        % Ground truth data
        GroundTruthPoints     % SamplePoints doubled up for training
        GroundTruthMeans      % SampleMeans doubled up for training
        
        % Predicted data (used to visualize the GP)
        TestPoints      % n rows by 2 col of (x,y) points to evaluate model
        TestMeshX       % n x n matrix meshgrid of X testpoints
        TestMeshY       % n x n matrix meshgrid of Y testpoints
        TestMeans       % n rows output by model
        NormalizedTestMeans % n rows output by model normalized between 0 and 1
        TestS2          % n rows output by model
        TestFigure      % handle to visualization
        
        % Voronoi cells for plotting
        VoronoiCells
        
        % Most recent centroid positions from weighted voronoi partition
        Centroids       % map<str(id), Position> of centroids of weighted voronoi partition
        CentroidsMatrix % simple nRobots x 2 matrix of x,y positions of centroids
        
        % Most recent circumcenter positions from weighted voronoi partition
        Circumcenters       % map<str(id), Position> of circumcenters of weighted voronoi partition
        CircumcentersMatrix % simple nRobots x 2 matrix of x,y circumcenters of centroids
        
        % Most recent uncertainty-maximizing positions from weighted voronoi partition
        MaxS2            % map<str(id), Position> of max uncertainty positions in weighted voronoi cells
        MaxS2Matrix      % simple nRobots x 2 matrix of x,y positions of max uncertainty points
        
        % Most recent random point in a region to sample
        RandomSample     % map<str(id), Position>
        RandomSampleMatrix
        
        % Other relevant GP data
        Hyp             % hyperparameters of GP model
        Model           % MFGP model from python code
        Loss            % Loss metric over time (sequence of entries)
        
        Idx
    end
    
    methods
        function obj = HILGPC_Data(environment, plotter, hilgpc_settings, mfgp_matlab)
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
            if obj.Settings.RecycleLofiPrior
                obj.RecycleLofiPrior();
            end
            
            if obj.Settings.RecycleHifiPrior
                obj.RecycleHifiPrior();
            end
            
            % initialize number of samples to zero
            obj.NumSamples = 0;
            obj.NumHifi = 0;
           
            
            % initialize python model
            obj.Model = mfgp_matlab.init_MFGP();
            
            obj.LoadGroundTruth();
            
            obj.Idx = 0;
            
        end
        
        function obj = GetLofiPrior(obj)
            % GETHumanPRIOR
            %   Take human input for estimations of mean and s2 to
            %   initialize the lofi prior for GP estimation
            
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
            % into SamplePoints, SampleMeans, HifiTrainPoints and HifiTrainMeans
            
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
                obj.LofiTrainPoints(2*i-1, 1:2) = obj.InputPoints(i, 1:2);
                obj.LofiTrainMeans(2*i-1, 1) = lower;
                
                % create upper bound train point on even indices
                obj.LofiTrainPoints(2*i, 1:2) = obj.InputPoints(i, 1:2);
                obj.LofiTrainMeans(2*i, 1) = upper;
                
            end
            
            % Set size member
            obj.NumLofi = size(obj.LofiTrainMeans,1);
        end
            
        function obj = GetHifiPrior(obj)
            % GETSAMPLEPRIOR
            %   Take human input for estimations of mean and s2 to
            %   initialize the hifi-prior for mfgp
            
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
            obj.SampleConfidence = str2double(confidence{1});
            
            
            % done with input -> convert inputs into [x,y] array and store
            % into SamplePoints, SampleMeans, HifiTrainPoints and HifiTrainMeans
            
            % (note: do not include last point, as it is from clicking
            % done button)
            for i = 1:size(inputs, 1)-1
                % store input point
                point = inputs{i, 1};
                [x,y] = point.ToPair();
                
                obj.SamplePoints(i, 1:2) = [x,y];
                
                % store input mean
                obj.SampleMeans(i, 1) = inputs{i, 2};
            end
            
            
            % add 2 points to the training set each offset by one stddev
            % to properly train model mean and variance given imperfect
            % human input
            
            % compute uncertainty
            uncertainty = 1 - obj.SampleConfidence;
            
            % iterate through input means and shift up and down to
            % upper/lower uncertainty bounds to create train means
            for i = 1:size(obj.SamplePoints, 1)
                
                % compute upper and lower bounds
                mean = obj.SampleMeans(i, 1);
                shift = uncertainty * mean;
                upper = mean + shift;
                lower = mean - shift;
                
                % create lower bound train point on odd indices
                obj.HifiTrainPoints(2*i-1, 1:2) = obj.SamplePoints(i, 1:2);
                obj.HifiTrainMeans(2*i-1, 1) = lower;
                
                % create upper bound train point on even indices
                obj.HifiTrainPoints(2*i, 1:2) = obj.SamplePoints(i, 1:2);
                obj.HifiTrainMeans(2*i, 1) = upper;
                
            end
            
            % Set size member
            obj.NumHifi = size(obj.HifiTrainMeans,1);
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
            title(sprintf("Click to indicate function mean over testbed on scale of 0-5"));
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
                
                scatter(ax, x, y, 200, level, 'filled');
            end
        end
        
        function obj = ComputeSFGP(obj)
            % Compute single-fidelity GP using gpml library from MIT
            
            % optimize hyperparameters
            obj.Hyp = minimize(obj.Hyp, @gp, -obj.Settings.MaxEvals, @infGaussLik, obj.Settings.MeanFunction,...
                obj.Settings.CovFunction, obj.Settings.LikFunction, obj.LofiTrainPoints, obj.LofiTrainMeans);
            
            % compute on testpoints
            [m, s2] = gp(obj.Hyp, @infGaussLik, obj.Settings.MeanFunction,...
                obj.Settings.CovFunction, obj.Settings.LikFunction, ...
                obj.LofiTrainPoints, obj.LofiTrainMeans, obj.TestPoints);
            
            % save testpoint means and s2
            obj.TestMeans = m;
            obj.TestS2 = s2;
            
        end
        
        function obj = ComputeMFGP(obj, mfgp_matlab)
           % Compute multi-fidelity GP using mfgp code from Paris Parklas
           
           % Human input is low fidelity
           X_L = obj.LofiTrainPoints;
           y_L = obj.LofiTrainMeans;
           
           % Sampled input is high fidelity
           X_H = obj.HifiTrainPoints;
           y_H = obj.HifiTrainMeans;
           
           % Update model
           if size(X_L, 1) > 1
               obj.Model = mfgp_matlab.update_MFGP_L(obj.Model, X_L, y_L);
           end
           
           if size(X_H, 1) > 1
               obj.Model = mfgp_matlab.update_MFGP_H(obj.Model, X_H, y_H);
           end
           
           % Predict using model
           % TestPoints is X_star
           X_star = obj.TestPoints;
           result = mfgp_matlab.predict_MFGP(obj.Model, X_star);
           mu = double(result{1})';
           var = double(result{2})';
           hyp = exp(double(obj.Model.hyp))
           
           obj.TestMeans = mu;
           obj.TestS2 = var;
 
        end
        
        function SaveData(obj)
           save(sprintf('data/human-data-%d.mat', obj.Idx), 'obj');
           obj.Idx = obj.Idx + 1;
        end
        
        function u = GetMaxUncertainty(obj)
            
            % return maximum uncertainty point in entire field
            u = max(obj.TestS2);
            
        end
        
        function obj = VisualizeGP(obj)
            
            obj.Plotter.PlotMean(obj.TestMeshX, obj.TestMeshY, obj.TestMeans);
            obj.Plotter.PlotVar(obj.TestMeshX, obj.TestMeshY, obj.TestS2);
%             if isempty(obj.TestFigure)
%                 obj.TestFigure = figure;
%             end
%             
%             ax = obj.TestFigure.CurrentAxes;
%             cla(ax);
%             axes(ax);
%             hold on;
%            
%             
%             if obj.Plotter.ShowTrainPoints
%                 % scatter ground truth from human
%                 scatter3(obj.InputPoints(:,1) , obj.InputPoints(:,2), obj.InputMeans, 'black', 'filled');
%                 
%                 % scatter Gaussian-shifted training points based on ground
%                 % truth of human
%                 scatter3(obj.LofiTrainPoints(:,1) , obj.LofiTrainPoints(:,2), obj.LofiTrainMeans(:,1), 'magenta', 'filled');
%             
%                 if size(obj.SamplePoints, 1) > 0
%                     % scatter points-to-sample in blue
%                     scatter3(obj.SamplePoints(:,1) , obj.SamplePoints(:,2), obj.SampleMeans(:,1), 'blue', 'filled');
%                     legend_text = ["Human-input ground truth", ...
%                     "Gaussian-shifted train points to account for confidence", ...
%                     "Points to sample", "Mean", "Lower CI-95", "Upper CI-95"];
%                 else
%                     legend_text = ["Human-input ground truth", ...
%                     "Gaussian-shifted train points to account for confidence", ...
%                     "Mean", "Lower CI-95", "Upper CI-95"];
%                 end
%             else
%                 legend_text = ["Mean", "Lower CI-95", "Upper CI-95"];
%             end
%             
%             % mesh GP surface
%             mesh(obj.TestMeshX, obj.TestMeshY, reshape(obj.TestMeans, size(obj.TestMeshX, 1), []));
%             colormap(gray);
%             
%             % mesh upper and lower 95CI bounds
%             lower_bound = obj.TestMeans - 2*sqrt(obj.TestS2);
%             upper_bound = obj.TestMeans + 2*sqrt(obj.TestS2);
%             mesh(obj.TestMeshX, obj.TestMeshY, reshape(lower_bound, size(obj.TestMeshX, 1), []),...
%                 'FaceColor', [0,1,1], 'EdgeColor', 'blue', 'FaceAlpha', 0.3);
%             mesh(obj.TestMeshX, obj.TestMeshY, reshape(upper_bound, size(obj.TestMeshX, 1), []),...
%                 'FaceColor', [0,1,0.5], 'EdgeColor', 'green', 'FaceAlpha', 0.3);
%         
%             title(sprintf("GP Function Estimate", obj.Settings.S2Threshold));
%             legend(legend_text, 'Location', 'Northeast');
%             
%             view(3)
%             xlim auto;
%             ylim auto;
%             zlim auto;
        end
        
        function UpdateModel(obj, positions, samples)
            % Update hifi training points given samples taken at x,y
            % positions
            
            % Rescale from analog 0-1024 scale to 0-5 scale
            samples = obj.RescaleSamples(samples);
           
            % Iterate over robots, saving current coordinate and light level
            % into sample points and sample means
            for i = 1:size(positions, 1)
                
                % Increment counter
                obj.NumSamples = obj.NumSamples + 1;
                obj.NumHifi = obj.NumHifi + 1;
                n_s = obj.NumSamples;
                n_h = obj.NumHifi;
                
                % Keep this robot id in SampleIds
                obj.SampleIds(n_s, 1) = i;
                
                % Keep this sample (x,y) in SamplePoints and add to Hifi
                % training set
                obj.SamplePoints(n_s, 1:2) = positions(i, 1:2);
                obj.HifiTrainPoints(n_h, 1:2) = positions(i, 1:2);
                
                % Keep this sample mean level in SampleMeans and add to
                % Hifi training set
                obj.SampleMeans(n_s, 1) = samples(i, 1);
                obj.HifiTrainMeans(n_h, 1) = samples(i, 1);
                
                % Report to user
                fprintf("Robot %d : %f at position (%f, %f)\n",...
                    i, samples(i,1), positions(i,1), positions(i,2));
            end
            fprintf("\n");
            
        end
        
        function samples = RescaleSamples(obj, samples)
            % Rescale readings from analog sensor to 0-5 scale for training
            
            samples = samples ./ 1024 .* 5;
            
        end
        
        function ExportGPToJpg(obj)
            %EXPORTGPTOJPG
            % Export a visualization of this GP to a jpg image for
            % projection
            
            % Plot mesh of GP
            figure;
            s = mesh(obj.TestMeshX, obj.TestMeshY, reshape(obj.TestMeans, size(obj.TestMeshX, 1), []));
            
            % Turn off axes and set 2d view
            set(gca, 'visible', 'off');
            view(2);
            
            % Set colormap
            colormap('gray');
            
            % Fill mesh with color and set background to black
            s.FaceColor = 'flat';
            set(gcf, 'color', 'black');
            
            % Autoscale axes and save
            axis([min(obj.TestPoints(:,1)), max(obj.TestPoints(:,1)), ...
                min(obj.TestPoints(:,2)), max(obj.TestPoints(:,2))]);
            
        end
        
        function LoadGroundTruth(obj)
            
            prior = readtable(obj.Settings.GroundTruthFilename);
            
            % save first two columns of (x,y) points without header row
            obj.GroundTruthPoints = prior{1:end, 1:2};
            
            % save third column of means without header row
            obj.GroundTruthMeans = prior{1:end, 3};
            
        end
        
        function RecycleLofiPrior(obj)
            % Given lofi prior, reconstruct from CSV
            
            prior = readtable(obj.Settings.LofiFilename);
            
            % save first two columns of (x,y) points without header row
            tempPoints = prior{1:end, 1:2};
            
            % save third column of means without header row
            tempMeans = prior{1:end, 3};
            
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
            for i = 1:size(tempMeans, 1)
                
                % compute upper and lower bounds
                mean = tempMeans(i, 1);
                shift = uncertainty * mean;
                upper = mean + shift;
                lower = mean - shift;
                
                % create lower bound train point on odd indices
                obj.LofiTrainPoints(2*i-1, 1:2) = tempPoints(i, 1:2);
                obj.LofiTrainMeans(2*i-1, 1) = lower;
                
                % create upper bound train point on even indices
                obj.LofiTrainPoints(2*i, 1:2) = tempPoints(i, 1:2);
                obj.LofiTrainMeans(2*i, 1) = upper;
                
            end
            
            % Set size member
            obj.NumLofi = size(obj.LofiTrainMeans,1);
            
        end
        
        function RecycleHifiPrior(obj)
            % Given hifi sample prior, reconstruct from CSV
            
            prior = readtable(obj.Settings.HifiFilename);
            
            % save first two columns of (x,y) points without header row
            tempPoints = prior{1:end, 1:2};
            
            % save third column of means without header row
            tempMeans = prior{1:end, 3};
            
            % save user confidence in fourth column without header row
            obj.SampleConfidence = prior{1, 4};
            
            % build test set
            % add 2 points to the training set each offset by one stddev
            % to properly train model mean and variance given imperfect
            % human input
            
            % compute uncertainty
            uncertainty = 1 - obj.SampleConfidence;
            
            % iterate through input means and shift up and down to
            % upper/lower uncertainty bounds to create train means
            for i = 1:size(tempMeans, 1)
                
                % compute upper and lower bounds
                mean = tempMeans(i, 1);
                shift = uncertainty * mean;
                upper = mean + shift;
                lower = mean - shift;
                
                % create lower bound train point on odd indices
                obj.HifiTrainPoints(2*i-1, 1:2) = tempPoints(i, 1:2);
                obj.HifiTrainMeans(2*i-1, 1) = lower;
                
                % create upper bound train point on even indices
                obj.HifiTrainPoints(2*i, 1:2) = tempPoints(i, 1:2);
                obj.HifiTrainMeans(2*i, 1) = upper;
                
            end
            
            % Set size member
            obj.NumHifi = size(obj.HifiTrainMeans,1);
        end
        
        function SavePrior(obj, filename, fidelity)
            
            if fidelity == "low"
                prior = cat(2, obj.InputPoints, obj.InputMeans);
                prior(1, 4) = obj.InputConfidence;
            else
                prior = cat(2, obj.SamplePoints, obj.SampleMeans);
                prior(1, 4) = obj.SampleConfidence;
            end
            
            
            file = fopen(filename, 'w');
            fprintf(file, "X,Y,Means,Confidence\n");
            fclose(file);
            
            dlmwrite(filename, prior, '-append');
            
        end
        
        function SaveSamples(obj, filename) 
            % After data collection, save samples to file with filename
            
            file = fopen(filename, 'w');
            fprintf(file, "X,Y,Sample,RobotId\n");
            fclose(file);
            
            samples = cat(2, obj.SamplePoints, obj.SampleMeans, obj.SampleIds);
            
            dlmwrite(filename, samples, '-append');
            
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

%             % Visualize Voronoi partitions and centroids
%             ax = obj.Plotter.AuxiliaryAxes;
%             cla(ax);
%             hold(ax, 'on');
%             
%             for i = 1:obj.Environment.NumRobots
%                 color = obj.Plotter.RobotColors(i,:);
%                 size = obj.Plotter.DotSize;
%                 pgon = polygons{i,1};
%                 plot(ax, polyshape(pgon(:,1), pgon(:,2)));
%                 scatter(ax, centroids(i,1), centroids(i,2), size, color, 'filled');
%             end
%             
%             
%             % Rescale axes and set title
%             title(ax, 'Exploit: Centroid Step');
%             ax.DataAspectRatio = [1,1,1];
                        
            % Step 6: Set CentroidsMatrix and Centroids fields with helper
            % method
            obj.CentroidsMatrix = centroids;
            obj.Centroids = obj.MatrixToPositions(centroids);      
            obj.VoronoiCells = polygons;
            
        end
        
        function ComputeCellMaxS2Cartogram(obj)
            % Given TestPoints, TestMeans, and TestSD taken as the demand function,
            % computes weighted voronoi partition of field given robot
            % positions specified by environment.Positions, then finds
            % uncertainty-maximizing point within each cell, and sets MaxS2
            % member variable accordingly. Utilizes cartogram
            % mapping to determine voronoi partition and maxS2 points in a
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
        
        function ComputeCellMaxS2Numerically(obj)
            % Given TestPoints, TestMeans, and TestSD taken as the demand function,
            % computes weighted voronoi partition of field given robot
            % positions specified by environment.Positions, then finds
            % uncertainty-maximizing point within each cell, and sets MaxS2
            % member variable accordingly. Utilizes voronoi partition in
            % the original space to determine set of MaxS2 points
            
            
            % Configure visualization for debugging
%             ax = obj.Plotter.AuxiliaryAxes;
%             cla(ax);
%             hold(ax, 'on');
            
            % Get current robot positions
            positions = obj.PositionsToMatrix();          
        
            % Step 1: Compute voronoi partition of original space and
            % initialize local variables
            px = positions(:,1);  % initializer points
            py = positions(:,2);
            corners = [min(obj.TestPoints(:,1)), min(obj.TestPoints(:,2));  % corners of polygon to be voronoi'd
                max(obj.TestPoints(:,1)), min(obj.TestPoints(:,2));
                max(obj.TestPoints(:,1)), max(obj.TestPoints(:,2));
                min(obj.TestPoints(:,1)), max(obj.TestPoints(:,2))];
            
            [vertices, cells] = Voronoi.VoronoiBounded(px, py, corners);
            
            % Step 2: Find uncertainty-maximizing points in each
            % Voronoi partition and add to set to be sampled
            max_s2_points = zeros(obj.Environment.NumRobots, 2);
            polygons = {};
            
            for i = 1:obj.Environment.NumRobots
                
                % Iterate through each Voronoi cell polygon
                cell = cells{i};
                polygon = vertices(cell, :); % subset the vertices of the polygon bounding just this cell
                polygons{i,1} = polygon;
                
                % Get indices of test points in this Voronoi cell polygon
                in_indices = inpolygon(obj.TestPoints(:,1), obj.TestPoints(:,2), polygon(:,1), polygon(:,2));
                
                % Get coordinates of points in this Voronoi cell polygon
                in_points = obj.TestPoints(in_indices, :);
                
                % Get uncertainties of points in this Voronoi cell polygon
                in_s2 = obj.TestS2(in_indices, :);
                
                % Find max uncertainty of this Voronoi cell polygon
                [max_s2, max_s2_index] = max(in_s2);
                
                % Store coordinates of this call's maxS2 point
                max_s2_point = in_points(max_s2_index,:);
                max_s2_points(i, :) = max_s2_point;
              
                % Visualize
%                 color = obj.Plotter.RobotColors(i,:);
%                 size = obj.Plotter.DotSize;
%                 plot(ax, polyshape(polygon(:,1), polygon(:,2)), 'FaceColor', color);
%                 scatter(ax, max_s2_point(:,1), max_s2_point(:,2), size, color, 'filled');
            end
            
            % Rescale axes and set title
%             title(ax, 'Explore: MaxS2 Step');
%             ax.DataAspectRatio = [1,1,1];

            % Step 3: Set MaxS2Matrix and MaxS2 fields with helper
            obj.MaxS2Matrix = max_s2_points;
            obj.MaxS2 = obj.MatrixToPositions(max_s2_points);  
            obj.VoronoiCells = polygons;
        end
        
        function ComputeRandomSearch(obj)
            % Given TestPoints, TestMeans, and TestSD taken as the demand function,
            % computes weighted voronoi partition of field given robot
            % positions specified by environment.Positions, then randomly
            % selects a point to sample within each region
            
            
            % Configure visualization for debugging
            ax = obj.Plotter.AuxiliaryAxes;
            cla(ax);
            hold(ax, 'on');
            
            % Get current robot positions
            positions = obj.PositionsToMatrix();          
        
            % Step 1: Compute voronoi partition of original space and
            % initialize local variables
            px = positions(:,1);  % initializer points
            py = positions(:,2);
            corners = [min(obj.TestPoints(:,1)), min(obj.TestPoints(:,2));  % corners of polygon to be voronoi'd
                max(obj.TestPoints(:,1)), min(obj.TestPoints(:,2));
                max(obj.TestPoints(:,1)), max(obj.TestPoints(:,2));
                min(obj.TestPoints(:,1)), max(obj.TestPoints(:,2))];
            
            [vertices, cells] = Voronoi.VoronoiBounded(px, py, corners);
            
            % Step 2: Find uncertainty-maximizing points in each
            % Voronoi partition and add to set to be sampled
            random_samples = zeros(obj.Environment.NumRobots, 2);
            
            for i = 1:obj.Environment.NumRobots
                
                % Iterate through each Voronoi cell polygon
                cell = cells{i};
                polygon = vertices(cell, :); % subset the vertices of the polygon bounding just this cell
                
                % Get indices of test points in this Voronoi cell polygon
                in_indices = inpolygon(obj.TestPoints(:,1), obj.TestPoints(:,2), polygon(:,1), polygon(:,2));

                % Get coordinates of points in this Voronoi cell polygon
                in_points = obj.TestPoints(in_indices, :);
                                
                % Randomly sample some point in this cell
                n = length(in_points);
                random_point = in_points(randi(n),:);
                random_samples(i, :) = random_point;
              
                % Visualize
                color = obj.Plotter.RobotColors(i,:);
                size = obj.Plotter.DotSize;
                plot(ax, polyshape(polygon(:,1), polygon(:,2)), 'FaceColor', color);
                scatter(ax, random_point(:,1), random_point(:,2), size, color, 'filled');
            end
            
            % Rescale axes and set title
            title(ax, 'Explore: Random Step');
            ax.DataAspectRatio = [1,1,1];

            % Step 3: Set MaxS2Matrix and MaxS2 fields with helper
            obj.RandomSampleMatrix = random_samples;
            obj.RandomSample = obj.MatrixToPositions(random_samples);  

        end
        
        function loss = ComputeLoss(obj)
           % Given a current state of robots, compute the loss WRT squared-distance from weight metric 
           
           % Get current robot positions
            positions = obj.PositionsToMatrix();          
        
            % Step 1: Compute voronoi partition of original space and
            % initialize local variables
            px = positions(:,1);  % initializer points
            py = positions(:,2);
            corners = [min(obj.TestPoints(:,1)), min(obj.TestPoints(:,2));  % corners of polygon to be voronoi'd
                max(obj.TestPoints(:,1)), min(obj.TestPoints(:,2));
                max(obj.TestPoints(:,1)), max(obj.TestPoints(:,2));
                min(obj.TestPoints(:,1)), max(obj.TestPoints(:,2))];
            
            [vertices, cells] = Voronoi.VoronoiBounded(px, py, corners);
            
            % Step 2: Iterate over entire point set in each cell and
            % compute loss WRT f
            loss = 0;
            
            for i = 1:obj.Environment.NumRobots
                                
                % Iterate through each Voronoi cell polygon
                cell = cells{i};
                polygon = vertices(cell, :); % subset the vertices of the polygon bounding just this cell
                
                % Get indices of test points in this Voronoi cell polygon
                in_indices = inpolygon(obj.GroundTruthPoints(:,1), obj.GroundTruthPoints(:,2), polygon(:,1), polygon(:,2));

                % Get coordinates of points in this Voronoi cell polygon
                in_points = obj.GroundTruthPoints(in_indices, :);
                in_means = obj.GroundTruthMeans(in_indices, :);
                                
                % Compute loss by squared distance times f integrated on V
                dist_sq = power((in_points(:,1) - positions(i,1)), 2) + power((in_points(:,2) - positions(i,2)), 2); %n x 1 vector
                weighted_dist = in_means .* dist_sq; % n x 1 vector
                avg_value = mean(weighted_dist); % scalar
                cell_loss = avg_value * polyarea(polygon(:,1), polygon(:,2));
                
                % Add cell loss to total and continue
                loss = loss + cell_loss;
                
            end
            
            % Step 3: Save loss
            obj.Loss = cat(1, obj.Loss, loss);

           
        end
        
        function mat = TargetsToMatrix(obj)
           % Helper function to convert environment.Positions map to a simple
           % nRobots x 2 matrix of x,y positions
           
           mat = zeros(obj.Environment.NumRobots, 2);
           map = obj.Environment.Targets;
           
           for i = 1:obj.Environment.NumRobots
               
               target = map(num2str(i));
               x = target.Center.X;
               y = target.Center.Y;
               mat(i, 1:2) = [x,y];
               
           end
           
        end
        
       
        function mat = PositionsToMatrix(obj)
           % Helper function to convert environment.Positions map to a simple
           % nRobots x 2 matrix of x,y positions
           
           mat = zeros(obj.Environment.NumRobots, 2);
           map = obj.Environment.Positions;
           oldmap = obj.Environment.Positions;
           
           for i = 1:obj.Environment.NumRobots
               try
                   position = map(num2str(i));
                   x = position.Center.X;
                   y = position.Center.Y;
                   mat(i, 1:2) = [x,y];
               catch
                   position = oldmap(num2str(i));
                   x = position.Center.X;
                   y = position.Center.Y;
                   mat(i, 1:2) = [x,y];
               end
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

