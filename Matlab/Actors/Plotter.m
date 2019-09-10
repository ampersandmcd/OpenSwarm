classdef Plotter
    %PLOTTER: Class to facilitate plotting of robot positions and other info
    
    properties
        Environment;        % Environment object dependency
        
        LocationAxes;       % axes on which to plot robot locations
        ColorImageAxes;     % axes on which to show current color image
        BWImageAxes;        % axes on which to show current bw image
        LightmapAxes;       % axes on which to show current lightmap
        
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
    end
    
    methods
        function obj = Plotter(inputEnvironment)
            %PLOTTER Construct a plotter object
            
            % initialize dependency
            obj.Environment = inputEnvironment;
            
            % configure preferences
            obj.XLabelOffset = 50;
            obj.YLabelOffset = 50;
            obj.DotSize = 36;
            obj.HeadingScalar = 5;
            
            obj.PositionColor = 'blue';
            obj.PositionTextColor = 'blue';
            
            obj.TargetColor = 'red';
            obj.TargetTextColor = 'red';
            
            obj.HeadingColor = 'blue';
            obj.HeadingTextColor = 'blue';
            
            % configure axes in which to plot: set title, aspect ratio and
            % axis limits
            subplot(2,2,1);
            title('Webcam: Color');
            obj.ColorImageAxes = gca();
            obj.ColorImageAxes.DataAspectRatio = [1,1,1];
            axis(obj.ColorImageAxes, [0, obj.Environment.XAxisSize, 0, obj.Environment.YAxisSize]);
            
            subplot(2,2,2);
            title('Webcam: BW');
            obj.BWImageAxes = gca();
            obj.BWImageAxes.DataAspectRatio = [1,1,1];
            axis(obj.BWImageAxes, [0, obj.Environment.XAxisSize, 0, obj.Environment.YAxisSize]);
            
            subplot(2,2,3);
            title('Robot Locations');
            obj.LocationAxes = gca();
            obj.LocationAxes.DataAspectRatio = [1,1,1];
            axis(obj.LocationAxes, [0, obj.Environment.XAxisSize, 0, obj.Environment.YAxisSize]);
            
            subplot(2,2,4);
            title('Auxiliary');
            obj.LightmapAxes = gca();
            obj.LightmapAxes.DataAspectRatio = [1,1,1];
            axis(obj.LightmapAxes, [0, obj.Environment.XAxisSize, 0, obj.Environment.YAxisSize]);
        end
        
        function obj = PlotColorImage(obj, img)
            %PlotColorImage: display a color image on ColorImageAxes
            imshow(img, 'Parent', obj.ColorImageAxes);
            title(obj.ColorImageAxes, 'Webcam: Color');
            obj.ColorImageAxes.Visible = 'On';
            set(obj.ColorImageAxes, 'box', 'off');
        end
        
        function obj = PlotBWImage(obj, img)
            %PlotBWImage: display a BW image on BWImageAxes
            imshow(img, 'Parent', obj.BWImageAxes);
            title(obj.BWImageAxes, 'Webcam: BW');
            obj.BWImageAxes.Visible = 'On';
            set(obj.BWImageAxes, 'box', 'off');
        end
        
        function obj = PlotPositions(obj)
            %PlotPositions:
            %   Plot current positions from Environment.Positions map.
            %   Plot target positions from Environment.Targets map.
            
            % clean up
            hold(obj.LocationAxes, 'off');
            cla(obj.LocationAxes);
            hold(obj.LocationAxes, 'on');
            
            % for each robot and its target in the positions map, plot and label
            for i = 1:obj.Environment.NumRobots
                position = obj.Environment.Positions(num2str(i));
                target = obj.Environment.Targets(num2str(i));
                
                % plot and label position, heading, (x,y) coords:
                scatter(obj.LocationAxes, position.Center.X, position.Center.Y, obj.DotSize, obj.PositionColor);
                quiver(obj.LocationAxes, position.Center.X, position.Center.Y, (position.Nose.X - position.Center.X) * obj.HeadingScalar, (position.Nose.Y - position.Center.Y) * obj.HeadingScalar, 'Color', obj.HeadingColor);
                message = sprintf('%0.0f\n(%0.0f, %0.0f)\n%0.0f°', i, position.Center.X, position.Center.Y, position.Heading);
                text(obj.LocationAxes, (position.Center.X + obj.XLabelOffset), (position.Center.Y + obj.YLabelOffset), message, 'Color', obj.PositionTextColor)
                
                % plot and label heading from center through nose point
                %text(obj.LocationAxes, (position.Center.X - obj.XLabelOffset), (position.Center.Y - obj.YLabelOffset), num2str(position.Heading), 'Color', obj.HeadingTextColor)

                % plot and label target
                scatter(obj.LocationAxes, target.Center.X, target.Center.Y, obj.DotSize, obj.TargetColor);
                text(obj.LocationAxes, (target.Center.X + obj.XLabelOffset), (target.Center.Y + obj.YLabelOffset), num2str(i), 'Color', obj.TargetTextColor)
                
            end
            
            % set axis scale, aspect ratio, and title
            axis(obj.LocationAxes, [0, obj.Environment.XAxisSize, 0, obj.Environment.YAxisSize]);
            obj.LocationAxes.DataAspectRatio = [1,1,1];
            title(obj.LocationAxes, 'Robot Locations');
            
        end
    end
end

