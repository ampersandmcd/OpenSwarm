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
        
        % Other relevant GP data
        Hyp             % hyperparameters of GP model
    end
    
    methods
        function obj = HILGPC_Data(environment, hilgpc_settings)
            % HILGPC_DATA
            %    Set environment dependency and generate test points
            
            % set dependencies
            obj.Environment = environment;
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
                          inputs{i, 2} = mod((inputs{i, 2} + 1), obj.Settings.MaxClicks);
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
            confidence = inputdlg('Enter confidence in your measurements, on a scale from 0 to 100');
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
                obj.TrainPoints(i, 1:2) = [x,y];
                
                % store input mean
                obj.InputMeans(i, 1) = inputs{i, 2};
                obj.TrainMeans(i, 1) = inputs{i, 2};
            end
            
            % returns with InputPoints, InputMeans, InputConfidence set
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
                + "scale of 1-%d, where 0 = no information,\n 1 = darkest and " ...
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
            obj.Hyp = minimize(obj.Hyp, @gp, -1000, @infGaussLik, obj.Settings.MeanFunction,...
                obj.Settings.CovFunction, obj.Settings.LikFunction, obj.TrainPoints, obj.TrainMeans);
            
            % compute on testpoints
            [m, s2] = gp(obj.Hyp, @infGaussLik, obj.Settings.MeanFunction,...
                obj.Settings.CovFunction, obj.Settings.LikFunction, ...
                obj.TrainPoints, obj.TrainMeans, obj.TestPoints);
            
            % save testpoint means and s2
            obj.TestMeans = m;
            obj.TestS2 = s2;
            
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
            scatter3(obj.TrainPoints(:,1) , obj.TrainPoints(:,2), obj.TrainMeans, 'black', 'filled');

            % mesh GP surface
            [plotX, plotY] = meshgrid(0:obj.Settings.GridResolution:obj.Environment.XAxisSize, ...
                                        0:obj.Settings.GridResolution:obj.Environment.YAxisSize);
            mesh(plotX, plotY, reshape(obj.TestMeans, size(plotX, 1), []));
            colormap(gray);
            
            % mesh upper and lower bounds
            lower_bound = obj.TestMeans - 2*sqrt(obj.TestS2);
            upper_bound = obj.TestMeans + 2*sqrt(obj.TestS2);
            mesh(plotX, plotY, reshape(lower_bound, size(plotX, 1), []), 'FaceColor', [0,1,1], 'EdgeColor', 'blue', 'FaceAlpha', 0.3);
            mesh(plotX, plotY, reshape(upper_bound, size(plotX, 1), []), 'FaceColor', [1,0.5,0], 'EdgeColor', 'red', 'FaceAlpha', 0.3);
        
            view(3)
        end
    end
end

