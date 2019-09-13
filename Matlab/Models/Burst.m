classdef Burst
    %BURST: Object used to represent the navigational "burst" command sent 
    %   to each robot
    
    properties
        Speed;      % Speed (between 0-100) at which robot should "burst"
        Angle;      % Angle which robot should turn before "burst"
    end
    
    methods
        function obj = Burst(inputSpeed, inputAngle)
            %BURST: Construct a Burst object
            obj.Speed = inputSpeed;
            obj.Angle = inputAngle;
        end
    end
end

