classdef Position
    %POSITION: Object to represent a robot's position in the field
    
    properties
        x;          % x position of the robot
        y;          % y position of the robot
        heading;      % heading angle robot is facing
    end
    
    methods
        function obj = Position(inputX, inputY, inputHeading)
            %POSITION: Construct a position object
            obj.x = inputX;
            obj.y = inputY;
            obj.heading = inputHeading;
        end
    end
end

