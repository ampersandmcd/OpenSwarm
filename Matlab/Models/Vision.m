classdef Vision
    %VISION: Object to encapsulate all image processing functionality
    
    properties
        % static properties and/or dependencies
        Environment;    % Environment object dependency
        Plotter;        % Plotter object dependency
        Camera;         % overhead webcam object
        BWThreshold;    % threshold with which binarize images to black/white when tracking
        AnchorSize;     % minimum size of visual tracking anchor in pixels used in denoising BW image
    
        % dynamic properties
        ColorImage;     % stores latest Color image
        BWImage;        % stores latest BW image
    
    end
    
    methods
        function obj = Vision(inputEnvironment, inputPlotter)
            %VISION Construct and configure a vision object
            
            obj.Environment = inputEnvironment;
            obj.Plotter = inputPlotter;
            obj = obj.StartCamera();
        end
        
        function obj = StartCamera(obj)
            %StartCamera: Clear image acquisition toolbox, startup
            %   environment camera, and automatically determine proper
            %   BWThreshold setting to track robots
            
            % configure camera
            imaqreset;
            obj.Camera = videoinput('winvideo', 1);
            triggerconfig(obj.Camera, 'manual');
            start(obj.Camera);
            
            % find and set BWThreshold
            obj.BWThreshold = obj.GetBWThreshold();
            
            % find and set AnchorSize
            obj.AnchorSize = obj.GetAnchorSize();
        end
        
        function obj = GetColorImage(obj)
            %GetColorImage: Takes and plots color image with environment camera
            
            obj.ColorImage = getsnapshot(obj.Camera);
            obj.Plotter = obj.Plotter.PlotColorImage(obj.ColorImage);
        end
        
        function obj = GetBWImage(obj)
            %GetBWImage: Takes and plots image with environment camera
            %   converted to black and white given BWThreshold and
            %   AnchorSize
            
            % get and plot new color image
            obj = obj.GetColorImage();
            
            % binarize, set, and plot
            bwImg = imbinarize(rgb2gray(obj.ColorImage), obj.BWThreshold);
            obj.BWImage = bwareaopen(bwImg, obj.AnchorSize);
            
            obj.Plotter = obj.Plotter.PlotBWImage(obj.BWImage);
        end
        
        function obj = UpdatePositions(obj)
            %UpdatePositions: Takes image, binarizes it, determines robot
            %   positions, and updates obj.Environment.Positions
            
            % get and plot new BW image
            obj = obj.GetBWImage();
            
            % get anchor points in the field as cell array
            anchorPoints = obj.GetAnchorPoints();
            
            % TODO: group anchor points with nearest neighbor search
            % TODO: create position objects given points
            % TODO: associate position objects with IDs in map<ID, pos>
            % TODO: update environment positions object
            disp('hello');
            
            
            
            % group nearest n = AnchorsPerRobot blobs into robot units
            
            
            
        end
        
        function anchorPoints = GetAnchorPoints(obj)
            %GetAnchorPoints: Takes image and returns cell array of Point
            %   objects, one for each anchor blob found in the image
            
            % find contiguous white blobs in image
            [anchorBlobs, numBlobs] = bwlabel(obj.BWImage);
            
            % assert proper number of blobs were found
            if numBlobs ~= obj.Environment.NumRobots * obj.Environment.AnchorsPerRobot
                warning('MISMATCHED ANCHOR COUNT: ensure NumRobots and AnchorsPerRobot are correct in Environment')
                return;
            end
            
            % find centroids of anchor points in field as x, y pairs 
            rawAnchorPoints = regionprops(anchorBlobs, 'Centroid');
        
            % convert struct of x,y pairs into struct of point objects
            anchorPoints = cell(size(rawAnchorPoints, 1), 1);        
            
            for i = 1:size(rawAnchorPoints, 1)
                orderedPair = rawAnchorPoints(i).Centroid;
                anchor = Point(orderedPair(1), orderedPair(2));
                anchorPoints{i} = anchor;
            end
        end
        
        function threshold = GetBWThreshold(obj)
            %FindBWThreshold: Determine optimal black/white cutoff
            %   threshold to properly deduce locations of robot visual anchors
            
            threshold = 0.9;
            %TODO: actually implement auto-set algorithm
        end
        
        function anchorSize = GetAnchorSize(obj)
           %GetAnchorSize: Determine optimal anchor size to properly deduce
           %    locations of robot visual anchors 
           
           anchorSize = 10;
           %TODO: actually implement auto-set algorithm
        end
    end
end

