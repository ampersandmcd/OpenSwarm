classdef Environment
    %ENVIRONMENT: Object to represent properties of test environment
    
    properties
        NumRobots;      % number of robots in field
        XAxisSize;      % width of field in pixels (determined by overhead webcam)
        YAxisSize;      % height of field in pixels (determined by overhead webcam)
        Camera;         % overhead webcam object
        BWThreshold;    % threshold to binarize images to black/white when tracking
        Iteration;      % counter variable tracking number of commands sent
        UDPTransmitter; % udp object to broadcast commands
        UDPReceiver;    % struct of udp objects to receive commands
        
        %TODO: add logging properties to environment
    end
    
    methods
        function obj = Environment()
            %ENVIRONMENT: Construct an instance of this class
            %   Manually configure the desired settings below:
            obj.NumRobots = 3;
            obj.XAxisSize = 1024;
            obj.YAxisSize = 768;
            obj.Iteration = 0;
            obj.UDPTransmitter = udp('10.10.10.255', 8080);
            
            % reset all io with cameras and UDP
            try
                fclose(instrfindall);
            catch
            end
        end
        
        function obj = StartCamera(obj)
            %StartCamera: Clear image acquisition toolbox and startup
            %   environment camera
            imaqreset;
            obj.Camera = videoinput('winvideo', 1);
            triggerconfig(obj.Camera, 'manual');
            start(obj.Camera);
        end
        
        function obj = StartUDPTransmitter(obj)
            %StartUDPTransmitter: open udp broadcaster
            fopen(obj.UDPTransmitter);
        end
        
        function obj = StartUDPReceiver(obj)
            %StartUDPReceiver: create and open udp receiver struct
            obj.UDPReceiver = {};
            for i = 1:obj.NumRobots
                % configure a udp receiver object with port 800<ID_NUM>
                receiver = udp('10.10.10.255', 'RemotePort', 8080, 'LocalPort', (8000 + i), 'Timeout', 0.01);
                fopen(receiver);
                obj.UDPReceiver{i} = receiver;
            end
        end
        
        function img = GetSnapshot(obj)
            %GetSnapshot: Takes and returns image with environment camera
            img = getsnapshot(obj.Camera);
        end
        
        function obj = Iterate(obj)
            %Iterate: Increments iteration count of environment
            obj.Iteration = obj.Iteration + 1;
        end
    end
end

