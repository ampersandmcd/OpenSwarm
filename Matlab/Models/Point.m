classdef Point
    %POINT: Represents a standard point in the cartesian plane
    
    properties
        X;  % x-coordinate of the point
        Y;  % y-coordinate of the point
    end
    
    methods
        function obj = Point(inputX, inputY)
            %POINT Construct a point object
            obj.X = inputX;
            obj.Y = inputY;
        end
        
        function distance = Distance(obj, otherPoint)
           dx = obj.X - otherPoint.X;
           dy = obj.Y - otherPoint.Y;
           distance = sqrt(dx^2 + dy^2);
        end
        
        function distance = DistanceFromOrigin(obj)
           distance = sqrt(obj.X^2 + obj.Y^2); 
        end
        
        function [x,y] = ToPair(obj)
            x = obj.X;
            y = obj.Y;
        end
    end
end

