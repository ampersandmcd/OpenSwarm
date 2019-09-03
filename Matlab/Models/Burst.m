classdef Burst
    %BURST: Object used to represent the navigational "burst" command sent 
    %   to each robot
    
    properties
        speed;
        angle;
    end
    
    methods
        function obj = Burst(inputSpeed, inputAngle)
            %BURST: Construct a Burst object
            obj.speed = inputSpeed;
            obj.angle = inputAngle;
        end
    end
end

