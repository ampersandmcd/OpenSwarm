classdef RobotSim
    %ROBOTSIM Simulated robot object used to imitate dynamics of
    %burst-based biwheeled robot
    %   Used to simulate OpenSwarm robots under COVID-19 shutdown
    
    properties
        Id              % int identifier of this simulated robot
        Position        % Position object describing the current robot
        SpeedCoeff      % Number of coordinate units moved in one 100-power burst
    end
    
    methods
        
        function obj = RobotSim(id, environment)
            %ROBOTSIM Construct an instance of a simulated robot

            obj.Id = id;
            obj.SpeedCoeff = 0.25;
            
            % randomly perturb startX to converge to different solutions
            % startX is in [100*id-25, 100*id+25]
            % step = (environment.XAxisSize - 2 * environment.EdgeGuard) / (2 * environment.NumRobots);
            % startX = ((2 * id - 1) * step + environment.EdgeGuard);
            % startY = environment.YAxisSize / 2;
            % noise = (rand(1) * step - step / 2); % UNUSED FOR NOW
            
            % Start X,Y randomly in space to experiment with convergence
            % conditions
            startX = (environment.XAxisSize - 2 * environment.EdgeGuard) * rand(1) + environment.EdgeGuard;
            startY = (environment.YAxisSize - 2 * environment.EdgeGuard) * rand(1) + environment.EdgeGuard;
            
            obj.Position = Position.SimPosition(startX, startY, 90);
        end
        
        function obj = Drive(obj, burst)
            % Drive
            %    Given angle and speed of burst, adjust Position member
            %    accordingly to drive along this burst
            angle = burst.Angle;
            speed = burst.Speed;
            
            obj.Position.Heading = mod((obj.Position.Heading + angle), 360);
            
            dx = cos(deg2rad(obj.Position.Heading)) * speed * obj.SpeedCoeff;
            dy = sin(deg2rad(obj.Position.Heading)) * speed * obj.SpeedCoeff;
            
            x0 = obj.Position.Center.X;
            y0 = obj.Position.Center.Y;
            
            obj.Position.Center = Point(x0 + dx, y0 + dy);
        end
        
    end
end

