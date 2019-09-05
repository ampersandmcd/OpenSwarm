classdef Utils
    %UTILS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        InvalidAnchorCountMessage = "The expected number of anchors were not detected in the webcam view."
        InvalidRobotCountMessage = "The expected number of robots were not found in the webacam view."
    end
    
    methods(Static)
        function Verify(condition, message)
            if ~condition
                warning(message);
            end
        end
    end
end

