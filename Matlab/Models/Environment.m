classdef Environment < handle
    %ENVIRONMENT: Object to represent properties of test environment
    
    properties
        % static configuration settings
        NumRobots;              % number of robots in field
        AnchorsPerRobot;        % number of visual anchors for tracking per robot
        XAxisSize;              % width of field in pixels (determined by overhead webcam)
        YAxisSize;              % height of field in pixels (determined by overhead webcam)
        EdgeGuard;              % padding around edges of field
        UDPTransmission;        % boolean indicating whether UDP transmissions will be sent
        UDPReception;           % boolean indicating whether UDP messages will be listened for
        ConvergenceThreshold;   % distance (px) to check against when determining if a robot has converged upon its target point
        FullSpeedThreshold      % distance (px) to check against when determining if robot should burst at full speed or reduced speed
        Delay                   % delay in sec to wait between commands
        GoHome                  % boolean indicating whether robots should return "home" at end of target map
        MaxIteration            % maximum number of iterations to run
        
        % simulation configuration settings
        IsSimulation            % boolean indicating whether we are running simulation or real experiment
        RobotSims               % container of RobotSim objects
        SimulationNoise         % parameter to control noisiness of observations under simulation
        
        % dynamic properties
        Iteration;      % counter variable tracking number of commands sent
        Positions;      % map<str(idnumber), Position> of robots in field
        OldPositions;   % cached
        Targets;        % map<str(idnumber), Position> of targets for robots in field
    end
    
    methods
        function obj = Environment(inputNumRobots, bounds, isSimulation, maxIteration)
            %Environment:
            %   Construct an environment object
                                    
            % Reset workspace and camera & UDP I/O
            try
                close all;
                clc;
                fclose(instrfindall);                
            catch
            end
            
            % Populate NumRobots from constructor input
            obj.NumRobots = inputNumRobots;
            obj.XAxisSize = round(bounds(3));
            obj.YAxisSize = round(bounds(4));
            obj.IsSimulation = isSimulation;
            obj.MaxIteration = maxIteration;
            
            % Manually populate other configuration settings below:
            obj.AnchorsPerRobot = 3;
            obj.Iteration = 1;      
            obj.UDPTransmission = true;
            obj.UDPReception = true;
            obj.ConvergenceThreshold = 5;
            obj.FullSpeedThreshold = 25;
            obj.Delay = 0;
            obj.GoHome = true;
            obj.EdgeGuard = 50;
            
            % construct simulated robots if simulated
            if obj.IsSimulation
                for i = 1:obj.NumRobots
                    obj.RobotSims{i,1} = RobotSim(i, obj);
                end
            end
        end
                
        function obj = Iterate(obj)
            %Iterate: 
            %   Increments iteration count of environment
            obj.Iteration = obj.Iteration + 1;
        end        
    end
end

