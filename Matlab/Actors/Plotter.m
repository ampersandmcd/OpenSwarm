classdef Plotter < handle
    %PLOTTER: Class to facilitate plotting of robot positions and other info
    
    properties
        Environment;        % Environment object dependency
        
        RobotColors;        % colormap to plot individual robots
        
        LocationAxes;       % axes on which to plot robot locations
        ColorImageAxes;     % axes on which to show current color image
        BWImageAxes;        % axes on which to show current bw image
        MeanAxes;           % axes on which to show current mean estimate
        VarAxes;            % axes on which to show current variance estimate
        LossAxes;           % axes on which to plot current loss
        ExploreAxes;        % axes on which to plot explore decision
        
        XLabelOffset;       % x-offset distance for labels on plots
        YLabelOffset;       % y-offset distance for labels on plots
        
        DotSize;            % dot marker size for plots
        HeadingScalar;      % scale factor to control length of heading vectors
        
        PositionColor;      % color in which to plot robot positions
        PositionTextColor;  % color in which to label robot positions
        
        TargetColor;        % color in which to plot robot targets
        TargetTextColor;    % color in which to label robot targets
        
        HeadingColor;       % color in which to plot heading vectors
        HeadingTextColor;   % color in which to label robot headings
        
        ShowTrainPoints     % Boolean setting to show training points
        
        Figure
        Idx
    end
    
    methods
        function obj = Plotter(inputEnvironment)
            %PLOTTER Construct a plotter object
            
            % initialize dependency
            obj.Environment = inputEnvironment;
            
            % configure preferences
            obj.RobotColors = lines(obj.Environment.NumRobots);
            
            obj.XLabelOffset = 50;
            obj.YLabelOffset = 50;
            obj.DotSize = 72;
            obj.HeadingScalar = 100;
            
            obj.PositionColor = 'blue';
            obj.PositionTextColor = 'blue';
            
            obj.TargetColor = 'red';
            obj.TargetTextColor = 'red';
            
            obj.HeadingColor = 'blue';
            obj.HeadingTextColor = 'blue';
            
            obj.ShowTrainPoints = false;
            
            obj.Figure = figure;
            obj.Idx = 0;
            
            % configure axes in which to plot: set title, aspect ratio and
            % axis limits
            subplot(3,2,1);
            title('Ground Truth & Loss Voronoi');
            obj.ColorImageAxes = gca();
            %obj.ColorImageAxes.DataAspectRatio = [1,1,1];
            %axis(obj.ColorImageAxes, [0, obj.Environment.XAxisSize, 0, obj.Environment.YAxisSize]);
                       
            subplot(3,2,2);
            title('Robot Locations & Lloyd Voronoi');
            obj.LocationAxes = gca();
            %obj.LocationAxes.DataAspectRatio = [1,1,1];
            %axis(obj.LocationAxes, [0, obj.Environment.XAxisSize, 0, obj.Environment.YAxisSize]);
            
            subplot(3,2,3);
            title('Posterior Mean');
            obj.MeanAxes = gca();
            %obj.MeanAxes.DataAspectRatio = [1,1,1];
            %axis(obj.MeanAxes, [0, obj.Environment.XAxisSize, 0, obj.Environment.YAxisSize]);
            
            subplot(3,2,4);
            title('Posterior Variance');
            obj.VarAxes = gca();
            %obj.VarAxes.DataAspectRatio = [1,1,1];
            axis(obj.VarAxes, [0, obj.Environment.XAxisSize, 0, obj.Environment.YAxisSize]);
            
            subplot(3,2,5);
            title('Loss by Iteration');
            obj.LossAxes = gca();
            
            subplot(3,2,6);
            title('Explore/Exploit by Robot');
            obj.ExploreAxes = gca();
            
            % display BW image if not simulated
            if ~obj.Environment.IsSimulation
                figure;
                gcf();
                obj.BWImageAxes = gca();
            end
            
        end
        
        function obj = PlotColorImage(obj, img)
            %PlotColorImage: display a color image on ColorImageAxes
            imshow(img, 'Parent', obj.ColorImageAxes);
            title(obj.ColorImageAxes, 'Webcam: Color');
            obj.ColorImageAxes.Visible = 'off';
            axis(obj.ColorImageAxes, 'xy');
        end
        
        function obj = PlotBWImage(obj, img)
            %PlotBWImage: display a BW image on BWImageAxes
            imshow(img, 'Parent', obj.BWImageAxes);
            title(obj.BWImageAxes, 'Webcam: BW');
            obj.BWImageAxes.Visible = 'off';
            axis(obj.BWImageAxes, 'xy');
        end
        
        function obj = PlotLoss(obj, loss)
           %PlotLoss: display loss on LossAxes and cumulative loss on
           %CumulativeLossAxes
           
           cla(obj.LossAxes);
           plot(obj.LossAxes, loss);
           r = refline(obj.LossAxes, 0, min(loss));
           r.Color = [0.5, 0.5, 0.5];
           r.LineStyle = ':';
           title(obj.LossAxes, 'Loss by Iteration');
           xlabel(obj.LossAxes, 'Iteration');
           ylabel(obj.LossAxes, 'Loss');
          
        end
        
        function obj = PlotMean(obj, meshX, meshY, mean)
           %PlotLoss: display loss on LossAxes 
           mesh(obj.MeanAxes, meshX, meshY, reshape(mean, size(meshX, 1), []),...
               'FaceColor', 'interp', 'EdgeColor', 'None');
           colormap('jet');
           view(obj.MeanAxes, 2);
           title(obj.MeanAxes, 'Posterior Mean');
        end
        
        function obj = PlotVar(obj, meshX, meshY, var)
           %PlotLoss: display loss on LossAxes 
           mesh(obj.VarAxes, meshX, meshY, reshape(var, size(meshX, 1), []),...
               'FaceColor', 'interp', 'EdgeColor', 'None');
           colormap('jet');
           view(obj.VarAxes, 2);
           title(obj.VarAxes, 'Posterior Variance');
        end
        
        function obj = PlotVoronoi(obj, polygons)
            %PlotVoronoi: display voronoi partition on location axes
            for i = 1:obj.Environment.NumRobots
               polygon = polygons{i,1};
               color = obj.RobotColors(i,:);
               plot(obj.LocationAxes, polyshape(polygon(:,1), polygon(:,2)),...
                   'FaceColor', color, 'EdgeColor', color);
            end
            
        end
        
        function obj = PlotExplore(obj, prob_explore, explore)
            %PlotExplore: display prob_explore and explore T/F variables on
            % explore axes
            
            cla(obj.ExploreAxes);
            
            % Plot bar graph of prob_explore
            b = bar(obj.ExploreAxes, prob_explore);
            
            % Color bar according to robot
            b.FaceColor = 'flat';
            b.CData = obj.RobotColors;
            ylim(obj.ExploreAxes, [0 1]);
            title(obj.ExploreAxes, "Probability of Exploration");
            
            
        end
        
        function obj = PlotLossVoronoiOverTruth(obj, polygons, meshX, meshY, truth)
            % Plot loss voronoi atop ground truth function
            
            % Clean axes
            hold(obj.ColorImageAxes, 'off');
            cla(obj.ColorImageAxes);
            hold(obj.ColorImageAxes, 'on');
            
            % Plot ground truth BELOW voronoi
            z = truth - max(truth);
            z = reshape(z, size(meshX, 1), []);
            mesh(obj.ColorImageAxes, meshX, meshY, z,...
                'FaceColor', 'interp', 'FaceAlpha', 1, 'EdgeColor', 'None');
            colormap('jet');
            view(obj.ColorImageAxes, 2);
            title(obj.ColorImageAxes, 'Ground Truth & Loss Voronoi');
            
            % Plot loss voronoi and current positions
            for i = 1:obj.Environment.NumRobots
                polygon = polygons{i,1};
                color = obj.RobotColors(i,:);
                plot(obj.ColorImageAxes, polyshape(polygon(:,1), polygon(:,2)),...
                    'EdgeColor', 'white', 'EdgeAlpha', 1,...
                    'FaceAlpha', 0.5, 'FaceColor', color, 'LineWidth', 1);
                
                position = obj.Environment.Positions(num2str(i));                
                scatter(obj.ColorImageAxes, position.Center.X, position.Center.Y,...
                    obj.DotSize, color, 'filled', 'MarkerEdgeColor', 'white');
            end          
        end
        
        function SaveFigure(obj)
            savefig(obj.Figure, sprintf('figures/human-figure-%d.fig', obj.Idx));
            obj.Idx = obj.Idx + 1;
        end
        
        function SavePng(obj)
            saveas(obj.Figure, sprintf('figures/figure-%d.png', obj.Idx));
            obj.Idx = obj.Idx + 1;
        end
        
        function obj = PlotPositions(obj)
            %PlotPositions:
            %   Plot current positions from Environment.Positions map.
            %   Plot target positions from Environment.Targets map.
            
            try
                % clean up
                hold(obj.LocationAxes, 'off');
                cla(obj.LocationAxes);
                hold(obj.LocationAxes, 'on');
                
                % for each robot and its target in the positions map, plot and label
                for i = 1:obj.Environment.NumRobots
                    position = obj.Environment.Positions(num2str(i));
                    target = obj.Environment.Targets(num2str(i));
                    
                    % plot and label position, heading, (x,y) coords:
                    scatter(obj.LocationAxes, position.Center.X, position.Center.Y, obj.DotSize, obj.RobotColors(i,:));
                    quiver(obj.LocationAxes, position.Center.X, position.Center.Y, cos(deg2rad(position.Heading)) * obj.HeadingScalar, sin(deg2rad(position.Heading)) * obj.HeadingScalar, 'Color', obj.RobotColors(i,:));
%                     message = sprintf('%0.0f\n(%0.0f, %0.0f)\n%0.0f°', i, position.Center.X, position.Center.Y, position.Heading);
%                     text(obj.LocationAxes, (position.Center.X + obj.XLabelOffset), (position.Center.Y + obj.YLabelOffset), message, 'Color', obj.RobotColors(i,:))
                    
                    % plot and label heading from center through nose point
                    % text(obj.LocationAxes, (position.Center.X - obj.XLabelOffset), (position.Center.Y - obj.YLabelOffset), num2str(position.Heading), 'Color', obj.RobotColors(i,:))
                    
                    % plot and label target
                    scatter(obj.LocationAxes, target.Center.X, target.Center.Y, obj.DotSize, obj.RobotColors(i,:), 'filled');
                    % text(obj.LocationAxes, (target.Center.X + obj.XLabelOffset), (target.Center.Y + obj.YLabelOffset), num2str(i), 'Color', obj.RobotColors(i,:))
                    
                end
                
                % set axis scale, aspect ratio, and title
                axis(obj.LocationAxes, [0, obj.Environment.XAxisSize, 0, obj.Environment.YAxisSize]);
                obj.LocationAxes.DataAspectRatio = [1,1,1];
                title(obj.LocationAxes, 'Robot Locations');
                
            catch
            end
                
        end
    end
end

