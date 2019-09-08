classdef Navigator
    %Navigator:
    %   Controls all navigational functionality, including target setting,
    %   updating, and command creation
    
    properties
        Environment;        % Environment object dependency
        TargetQueue;        % Cell array of Map<int, Position> where entry i is the target position map of the ith step
        TargetIndex;        % Index of the current target set in TargetQueue
        NumTargets;         % Number of targets in TargetQueue
    end
    
    methods
        function obj = Navigator(inputEnvironment)
            %Navigator:
            %   Construct a navigator object
            
            obj.Environment = inputEnvironment;
            obj.TargetIndex = 0;                    % not yet set
        end
        
        function obj = UpdateTargets(obj)
            %UpdateTargets:
            %   Update targets map<int, Position> of of Environment with
            %   the next set of targets in the master list
            
            % iterate TargetIndex to next step
            obj.TargetIndex = obj.TargetIndex + 1;
            
            % if more targets exist in queue, update Environment.Targets
            if obj.TargetIndex <= obj.NumTargets
                obj.Environment.Targets = obj.TargetQueue{obj.TargetIndex};
            end            
        end
        
        function obj = SetTargetsFromCSV(obj, filename)
            %SetTargetsFromCSV:
            %   Create list of map<int, position> specifying targets and
            %   set into TargetQueue, then set first target by calling
            %   UpdateTargets.
            %
            %   CSV should contain NumRobots rows and 2*NumTargets columns
            %   Row i should specify a series of (x,y) targets for robot i
            %   as follows: 
            %       (x1,y1) are entries in (rowicol1, rowicol2),
            %       (x2,y2) are entries in (rowicol3, rowicol4), etc.
            
            rawTargets = csvread(filename);
            targetQueue = cell(size(rawTargets, 2) / 2, 1);
            
            for col = 1:2:size(rawTargets, 2)
                % iterate over EVERY SECOND column (sequence) of target
                % points; recall that odd-col entries are x targets, and
                % even-col entries are y targets
                
                targetMap = containers.Map;
                
                for row = 1:size(rawTargets, 1)
                    % iterate over each row (robot) of targets and create
                    % map for this target set
                    targetX = rawTargets(row, col);
                    targetY = rawTargets(row, col+1);
                    targetPosition = Position.TargetPosition(targetX, targetY);
                    targetMap(num2str(row)) = targetPosition;
                end
                
                % add current targetMap target set to queue
                targetIndex = (col + 1) / 2; % deal with double-column-spacing of columns
                targetQueue{targetIndex} = targetMap;
            end
            
            obj.TargetQueue = targetQueue;
            obj.NumTargets = numel(targetQueue);
            
            obj = obj.UpdateTargets();
        end
    end
end

