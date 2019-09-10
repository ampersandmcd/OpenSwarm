classdef Utils
    %UTILS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        InvalidAnchorCountMessage = "The expected number of anchors were not detected in the webcam view."
        InvalidRobotCountMessage = "The expected number of robots were not found in the webacam view."
    
        InvalidTargetRowsMessage = 'Target CSV rows mismatch the expected number of robots'
        TargetXOOBMessage = 'Target CSV contains x coordinates out of bounds';
        TargetYOOBMessage = 'Target CSV contains y coordinates out of bounds';
    end
    
    methods(Static)
        function Verify(condition, message)
            %Verify:
            %   Print a warning message if condition is false to assist in
            %   debugging.
            %
            %   Can easily be changed to assert false and halt execution if
            %   desired.
            
            if ~condition
                warning(message);
            end
        end
        
        function theta = ArctanInDegrees(dx, dy)
            %ArctanInDegrees:
            %   Return the heading angle of the vector defined by [dx, dy]
            %   in degrees in the range [0, 360]
            
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
            
            theta = rad2deg(theta);
        end
    end
end

