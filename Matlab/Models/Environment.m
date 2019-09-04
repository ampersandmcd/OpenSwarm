classdef Environment
    %ENVIRONMENT: Object to represent properties of test environment
    
    properties
        NumRobots;      % number of robots in field
        XAxisSize;      % width of field in pixels (determined by overhead webcam)
        YAxisSize;      % height of field in pixels (determined by overhead webcam)
        Camera;         % overhead webcam object
        BWThreshold;    % threshold to binarize images to black/white when tracking
        Iteration;      % counter variable tracking number of commands sent
               
        %TODO: add logging properties to environment
    end
    
    methods
        function obj = Environment()
            %ENVIRONMENT: Construct an environment object
            
            % reset workspace and camera & UDP I/O
            try
                close all;
                clc;
                fclose(instrfindall);                
            catch
            end
            
            % Manually configure the desired settings below:
            obj.NumRobots = 3;
            obj.XAxisSize = 1024;
            obj.YAxisSize = 768;
            obj.Iteration = 0;
            
            
        end
                
        function obj = Iterate(obj)
            %Iterate: Increments iteration count of environment
            obj.Iteration = obj.Iteration + 1;
        end
    end
end

