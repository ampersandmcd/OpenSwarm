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
    end
end

