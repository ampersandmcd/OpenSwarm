classdef Environment
    %ENVIRONMENT: Object to represent properties of test environment
    
    properties
        NumRobots;      % number of robots in field
        XAxisSize;      % width of field in pixels (determined by overhead webcam)
        YAxisSize;      % height of field in pixels (determined by overhead webcam)
        Camera;         % overhead webcam object
        Iteration;      % counter variable tracking number of commands sent
    end
    
    methods
        function obj = Environment()
            %ENVIRONMENT: Construct an instance of this class
            %   Manually configure the desired settings below:
            obj.NumRobots = 3;
            obj.XAxisSize = 1024;
            obj.YAxisSize = 768;
            obj.Iteration = 0;
            
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

