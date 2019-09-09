classdef Environment < handle
    %ENVIRONMENT: Object to represent properties of test environment
    
    properties
        % static configuration settings
        NumRobots;              % number of robots in field
        AnchorsPerRobot;        % number of visual anchors for tracking per robot
        XAxisSize;              % width of field in pixels (determined by overhead webcam)
        YAxisSize;              % height of field in pixels (determined by overhead webcam)
        UDPTransmission;        % boolean indicating whether UDP transmissions will be sent
        UDPReception;           % boolean indicating whether UDP messages will be listened for
        ConvergenceThreshold;   % distance (px) to check against when determining if a robot has converged upon its target point
        FullSpeedThreshold      % distance (px) to check against when determining if robot should burst at full speed or reduced speed
        
        % dynamic properties
        Iteration;      % counter variable tracking number of commands sent
        Positions;      % map<str(idnumber), Position> of robots in field
        Targets;        % map<str(idnumber), Position> of targets for robots in field
        %TODO: add logging properties to environment
    end
    
    methods
        function obj = Environment()
            %Environment:
            %   Construct an environment object
            
            % reset workspace and camera & UDP I/O
            try
                close all;
                clc;
                fclose(instrfindall);                
            catch
            end
            
            % Manually configure the desired settings below:
            obj.NumRobots = 3;
            obj.AnchorsPerRobot = 3;
            obj.XAxisSize = 1024;
            obj.YAxisSize = 768;
            obj.Iteration = 0;      
            obj.UDPTransmission = true;
            obj.UDPReception = false;
            obj.ConvergenceThreshold = 50;
            obj.FullSpeedThreshold = 100;
        end
                
        function obj = Iterate(obj)
            %Iterate: 
            %   Increments iteration count of environment
            obj.Iteration = obj.Iteration + 1;
        end        
    end
end

