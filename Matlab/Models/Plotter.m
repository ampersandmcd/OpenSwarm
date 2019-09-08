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
            
            obj.HeadingColor = 'green';
            obj.HeadingTextColor = 'green';
            
            % configure axes in which to plot
            subplot(2,2,1);
            title('Webcam: Color');
            obj.ColorImageAxes = gca();
            
            subplot(2,2,2);
            title('Webcam: BW');
            obj.BWImageAxes = gca();
            
            subplot(2,2,3);
            title('Robot Locations');
            obj.LocationAxes = gca();
            
            subplot(2,2,4);
            title('Auxiliary');
            obj.LightmapAxes = gca();
        end
        
        function obj = PlotColorImage(obj, img)
            %PlotColorImage: display a color image on ColorImageAxes
            imshow(img, 'Parent', obj.ColorImageAxes);
            title(obj.ColorImageAxes, 'Webcam: Color');
        end
        
        function obj = PlotBWImage(obj, img)
            %PlotBWImage: display a BW image on BWImageAxes
            imshow(img, 'Parent', obj.BWImageAxes);
            title(obj.BWImageAxes, 'Webcam: BW');
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
                
                % plot and label position
                scatter(obj.LocationAxes, position.Center.X, position.Center.Y, obj.DotSize, obj.PositionColor);
                text(obj.LocationAxes, (position.Center.X + obj.XLabelOffset), (position.Center.Y + obj.YLabelOffset), num2str(i), 'Color', obj.PositionTextColor)
                
                % plot and label heading from center through nose point
                quiver(obj.LocationAxes, position.Center.X, position.Center.Y, (position.Nose.X - position.Center.X) * obj.HeadingScalar, (position.Nose.Y - position.Center.Y) * obj.HeadingScalar, 'Color', obj.HeadingColor);
                text(obj.LocationAxes, (position.Center.X - obj.XLabelOffset), (position.Center.Y - obj.YLabelOffset), num2str(position.Heading), 'Color', obj.HeadingTextColor)

                % plot and label target
                scatter(obj.LocationAxes, target.Center.X, target.Center.Y, obj.DotSize, obj.PositionColor);
                text(obj.LocationAxes, (target.Center.X + obj.XLabelOffset), (target.Center.Y + obj.YLabelOffset), num2str(i), 'Color', obj.TargetTextColor)
                
            end
            
            axis(obj.LocationAxes, [0, obj.Environment.XAxisSize, 0, obj.Environment.YAxisSize]);
            title(obj.LocationAxes, 'Robot Locations');
            
        end
    end
end

