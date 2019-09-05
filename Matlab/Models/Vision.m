classdef Vision
    %VISION: 
    %   Object to encapsulate all image processing functionality
    
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
            %VISION: 
            %   Construct and configure a vision object
            
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
            %GetColorImage: 
            %   Takes and plots color image with environment camera
            
            obj.ColorImage = getsnapshot(obj.Camera);
            obj.Plotter = obj.Plotter.PlotColorImage(obj.ColorImage);
        end
        
        function obj = GetBWImage(obj)
            %GetBWImage: 
            %   Takes and plots image with environment camera
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
            
            % get n-tuples grouping anchor points (where n=AnchorsPerRobot)
            anchorGroups = obj.GetAnchorGroups(anchorPoints);
            
            % create cell array of position objects from anchor point triplets
            positions = obj.GetPositions(anchorPoints, anchorGroups);
            
            % TODO: create position objects given points
            % UPDATE POSITION CONSTRUCTOR
            % TODO: associate position objects with IDs in map<ID, pos>
            % TODO: update environment positions object
            disp('hello');        
        
        end
        
        function positions = GetPositions(obj, anchorPoints, anchorGroups)
           %GetPositions: 
           %    Takes cell array of anchorPoints, along with cell
           %    array of anchorGroups containing index-triplets of
           %    grouped entries in anchorPoints.
           %    Returns cell array of size NumRobots x 1 containing
           %    position objects of grouped anchorPoints
           %    (i.e., the points with indices grouped in a triplet in the
           %    anchorGroups cell array)
           
           % create empty cell array in which to return Positions
           positions = cell(size(anchorGroups));
           
           for i = 1:obj.Environment.NumRobots
               % get current three anchor points
               anchorGroup = anchorGroups{i};
               anchors = anchorPoints(anchorGroup);
               
               % construct and store position from current three anchor
               % points
               position = Position(anchors{1}, anchors{2}, anchors{3});
               positions{i} = position;
           end
           
           % check that proper number of position objects were constructed
           Utils.Verify(numel(positions) == obj.Environment.NumRobots, Utils.InvalidRobotCountMessage);
        end
        
        function anchorPoints = GetAnchorPoints(obj)
            %GetAnchorPoints: 
            %   Takes image and returns cell array of Point
            %   objects, one for each anchor blob found in the image
            
            % find contiguous white blobs in image
            [anchorBlobs, numBlobs] = bwlabel(obj.BWImage);
            
            % check that proper number of blobs were found
            Utils.Verify(numBlobs == obj.Environment.NumRobots * obj.Environment.AnchorsPerRobot, Utils.InvalidAnchorCountMessage);
                            
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
        
        function anchorGroups = GetAnchorGroups(obj, anchorPoints)
            %GetAnchorGroups: 
            %   Takes cell vector of Point objects marking
            %   anchor points as ordered pairs.
            %   Returns cell vector of length NumRobots where each cell is 
            %   a vector of length AnchorsPerRobot and contains the indices 
            %   of the anchors corresponding to a single robot.
            %   NOTE: Assumes 3 anchors per robot to enable heading
            %   determination.
            
            % create anchorPoints x 1 cell array to store triplets
            anchorGroups = cell(obj.Environment.NumRobots, 1);
            
            % create counter to track number of groups found
            groupsFound = 0;
            
            for i = 1:numel(anchorPoints)
               % consider each point in the list
               currentAnchor = anchorPoints{i};
               
               % initialize nearest neighbors
               neighborOneId = 0;
               neighborOneDist = Inf;
               neighborTwoId = 0;
               neighborTwoDist = Inf;
               
               for j = 1:numel(anchorPoints)
                   % consider all other points in this list EXCEPT i=j
                   if i == j
                      continue; % skip this iteration
                   end
                   
                   otherAnchor = anchorPoints{j};
                   distance = currentAnchor.Distance(otherAnchor);
                   
                   if (distance < neighborOneDist)
                       % update nearest AND second nearest neighbor
                       neighborTwoId = neighborOneId;
                       neighborTwoDist = neighborOneDist;
                       
                       neighborOneId = j;
                       neighborOneDist = distance;
                   elseif (currentAnchor.Distance(otherAnchor) < neighborTwoDist)
                      % update only second nearest neighbor 
                      neighborTwoId = j;
                      neighborTwoDist = distance;
                   end                 
               end
               
               % at this point, currentAnchor, neighborOne, and neighborTwo
               % constitute a triplet of indices to be returned together
               
               % create triplet and sort
               anchorGroup = [i, neighborOneId, neighborTwoId];
               anchorGroup = sort(anchorGroup);
               
               % add triplet to anchorGroups cell array of triplet vectors
               % if not already present
               if ~ContainsAnchor(obj, anchorGroups, anchorGroup)
                  groupsFound = groupsFound + 1;
                  anchorGroups{groupsFound} = anchorGroup;
               end
            end
            
            % check that proper number of groups were found
            Utils.Verify(numel(anchorGroups) == obj.Environment.NumRobots, Utils.InvalidRobotCountMessage);
        end
        
        function found = ContainsAnchor(obj, anchorGroups, target)
            %ContainsAnchor: 
            %   Takes cell array of anchorGroups
            %   index-triplets and returns true if the triplet target is
            %   present in the array; else, false
            
            % set flag
            found = false;
            
            for k = 1:numel(anchorGroups)
                otherGroup = anchorGroups{k};
                if isequal(otherGroup, target)
                    % found
                    found = true;
                    return;
                end
            end
        end
        
        function threshold = GetBWThreshold(obj)
            %FindBWThreshold: 
            %   Determine optimal black/white cutoff
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

