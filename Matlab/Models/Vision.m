classdef Vision
    %VISION: Object to encapsulate all image processing functionality
    
    properties
        Environment;    % Environment object dependency
        Camera;         % overhead webcam object
        BWThreshold;    % threshold to binarize images to black/white when tracking
    end
    
    methods
        function obj = Vision(inputEnvironment)
            %VISION Construct and configure a vision object
            obj.Environment = inputEnvironment;
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
        end
        
        function img = GetSnapshot(obj)
            %GetSnapshot: Takes and returns image with environment camera
            img = getsnapshot(obj.Camera);
        end
        
        function img = GetBWSnapshot(obj)
            %GetBWSnapshot: Takes and returns image with environment camera
            %   converted to black and white with BWThreshold
            img = getsnapshot(obj.Camera);
        end
        
        function threshold = GetBWThreshold(obj)
            threshold = 5;
            %FindBWThreshold: Take photo and compare against expected
            %number of visual tracking "blobs"
        end
    end
end

