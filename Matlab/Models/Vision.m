classdef Vision
    %VISION: Object to encapsulate all image processing functionality
    
    properties
        Camera;         % overhead webcam object
        Environment;    % Environment object dependency
    end
    
    methods
        function obj = Vision(inputEnvironment)
            %VISION Construct a vision object
            obj.Environment = inputEnvironment;
        end
        
        function obj = StartCamera(obj)
            %StartCamera: Clear image acquisition toolbox and startup
            %   environment camera
            imaqreset;
            obj.Camera = videoinput('winvideo', 1);
            triggerconfig(obj.Camera, 'manual');
            start(obj.Camera);
        end
        
        function img = GetSnapshot(obj)
            %GetSnapshot: Takes and returns image with environment camera
            img = getsnapshot(obj.Camera);
        end
    end
end

