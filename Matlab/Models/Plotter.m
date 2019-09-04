classdef Plotter
    %PLOTTER: Class to facilitate plotting of robot positions and other info
    
    properties
        Environment;        % Environment object dependency
        LocationAxes;       % axes on which to plot robot locations
        ColorImageAxes;     % axes on which to show current color image
        BWImageAxes;        % axes on which to show current bw image
        LightmapAxes;       % axes on which to show current lightmap
    end
    
    methods
        function obj = Plotter(inputEnvironment)
            %PLOTTER Construct a plotter object
            
            obj.Environment = inputEnvironment;
            
            figure('Name', 'Robot Locations');
            obj.LocationAxes = gca();
            
            figure('Name', 'Webcam: Color');
            obj.ColorImageAxes = gca();
            
            figure('Name', 'Webcam: BW');
            obj.BWImageAxes = gca();
            
            figure('Name', 'Lightmap');
            obj.LightmapAxes = gca();
        end
        
        function obj = PlotColorImage(obj, img)
           %PlotColorImage: display a color image on ColorImageAxes
           imshow(img, 'Parent', obj.ColorImageAxes);
        end
        
        function obj = PlotBWImage(obj, img)
           %PlotBWImage: display a BW image on BWImageAxes
           imshow(img, 'Parent', obj.BWImageAxes);
        end
    end
end

