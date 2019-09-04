classdef Position
    %POSITION: Object to represent a robot's position in the field
    %   Given 3 anchor points on each robot arranged in an isoceles
    %   triangle, we assume the "nose" of the robot is opposite the short
    %   side of the isoceles triangle
    
    properties
        AnchorL;    % bottom-left anchor point of the robot
        AnchorR;    % bottom-right anchor point of the robot
        AnchorH;    % nose anchor point of the robot (opposite short side of isoceles triangle)
        Center;     % center point of the robot
        Heading;    % heading angle robot is facing
    end
    
    methods
        function obj = Position(inputAnchorA, inputAnchorB, inputAnchorC)
            %POSITION: Construct a position object given only the three
            %   anchor points represented as Point objects
            
            
        end
    end
end

