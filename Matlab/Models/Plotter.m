classdef Plotter
    %PLOTTER: Class to facilitate plotting of robot positions and other info
    
    properties
        LocationAxes;       % axes on which to plot robot locations
        ColorImageAxes;     % axes on which to show current color image
        BWImageAxes;        % axes on which to show current bw image
        LightmapAxes;       % axes on which to show current lightmap
    end
    
    methods
        function obj = Plotter()
            %PLOTTER Construct a plotter object
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
    end
end

