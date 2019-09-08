classdef Position
    %POSITION: Object to represent a robot's position in the field
    %   Given 3 anchor points on each robot arranged in an isoceles
    %   triangle, we assume the "nose" of the robot is opposite the short
    %   side of the isoceles triangle
    
    properties
        Nose;    % nose anchor point of the robot (opposite short side of isoceles triangle)
        Center;     % center point of the robot
        Heading;    % heading angle robot is facing
    end
    
    methods
                
        function obj = Position(inputAnchorA, inputAnchorB, inputAnchorC)
            %Position: Construct a position object given the three
            %   anchor points represented as Point objects.
            %   Used to construct position of actual robot in field
            
            % determine centroid of robot
            centerX = mean([inputAnchorA.X, inputAnchorB.X, inputAnchorC.X]);
            centerY = mean([inputAnchorA.Y, inputAnchorB.Y, inputAnchorC.Y]);
            obj.Center = Point(centerX, centerY);
                        
            % determine shortest side of triangle; the opposite vertex is
            % the nose anchor point
            sideAB = inputAnchorA.Distance(inputAnchorB);
            sideBC = inputAnchorB.Distance(inputAnchorC);
            sideCA = inputAnchorC.Distance(inputAnchorA);
            
            if min([sideAB, sideBC, sideCA]) == sideAB
                % vertex C is nose
                obj.Nose = inputAnchorC;
            elseif min([sideAB, sideBC, sideCA]) == sideBC
                % vertex A is nose
                obj.Nose = inputAnchorA;
            else
                % vertex B is nose
                obj.Nose = inputAnchorB;
            end
            
            % compute heading of robot in degrees by comparing location of
            % center point with nose point
            %   note: 0 degrees assumes robot is facing right in the plane
            %   angles increase from [0, 360] CCW, as is standard
            dx = obj.Nose.X - obj.Center.X;
            dy = obj.Nose.Y - obj.Center.Y;
            theta = 0;
            
            if dx > 0 && dy > 0
                % first quadrant
                theta = atan(dy/dx);
            elseif dx < 0 && dy > 0
                % second quadrant; add pi since range(atan) = [-pi/2, pi/2]
                theta = atan(dy/dx) + pi;
            elseif dx < 0 && dy < 0
                % third quadrant; add pi since range(atan) = [-pi/2, pi/2]
                theta = atan(dy/dx) + pi;                
            else 
                % fourth quadrant; add 2*pi since range(atan) = [-pi/2, pi/2]
                theta = atan(dy/dx) + 2*pi;
            end
            
            obj.Heading = rad2deg(theta);
        end
        
        function obj = TargetPosition(inputX, inputY)
            %TargetPosition: Construct position object given only center X and
            %   center Y.
            %   Used to construct position of target in field.
            %   Leaves Nose and Heading properties unset (not needed for
            %   target).
            
            obj.Center = Point(inputX, inputY);
        end
        
        function distance = DistanceFromOrigin(obj)
            distance = obj.Center.DistanceFromOrigin();
        end
    end
end

