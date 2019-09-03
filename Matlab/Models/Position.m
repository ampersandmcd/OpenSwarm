classdef Position
    %POSITION: Object to represent a robot's position in the field
    
    properties
        x;          % x position of the robot
        y;          % y position of the robot
        angle;      % heading angle robot is facing
    end
    
    methods
        function obj = Position(inputX, inputY, inputAngle)
            %POSITION Construct a position object
            obj.x = inputX;
            obj.y = inputY;
            obj.angle = inputAngle;
        end
    end
end

