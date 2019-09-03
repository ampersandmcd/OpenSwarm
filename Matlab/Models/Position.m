classdef Position
    %POSITION: Object to represent a robot's position in the field
    
    properties
        X;          % x position of the robot
        Y;          % y position of the robot
        Heading;    % heading angle robot is facing
    end
    
    methods
        function obj = Position(inputX, inputY, inputHeading)
            %POSITION: Construct a position object
            obj.X = inputX;
            obj.Y = inputY;
            obj.Heading = inputHeading;
        end
    end
end

