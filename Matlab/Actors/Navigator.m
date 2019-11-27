classdef Navigator < handle
    %Navigator:
    %   Controls all navigational functionality, including target setting,
    %   updating, and command creation
    
    properties
        % object dependencies
        Environment;        % Environment object dependency
        Plotter;            % Plotter object dependency
        
        % dynamic variables
        TargetQueue;        % Cell array of Map<int, Position> where entry i is the target position map of the ith step
        TargetIndex;        % Index of the current target set in TargetQueue
        NumTargets;         % Number of targets in TargetQueue
    end
    
    methods
        function obj = Navigator(inputEnvironment, inputPlotter)
            %Navigator:
            %   Construct a navigator object
            
            obj.Environment = inputEnvironment;
            obj.Plotter = inputPlotter;
            obj.TargetIndex = 0;                    % not yet set
        end
        
        function haltDirections = GetHaltDirections(obj)
            %GetHaltDirections:
            %    Return directions map<str(ID), burst> with all bursts
            %    set to speed=angle=0
            haltDirections = containers.Map;
            halt = Burst(0,0);
            
            for i = 1:obj.Environment.NumRobots
                haltDirections(num2str(i)) = halt;
            end
        end
        
        function homeTargets = GetHomeTargets(obj)
            %GetHomeDirections:
            %    Set target of robot i to (i * XAxisSize / (NumRobots + 1), YAxisSize / 5)
            %    and return map<str(int), position> of such targets
            
            homeTargets = containers.Map;
            
            for i = 1:obj.Environment.NumRobots
                homeX = (i * obj.Environment.XAxisSize) / (obj.Environment.NumRobots + 1);
                homeY = obj.Environment.YAxisSize / 5;
                homePosition = Position.TargetPosition(homeX, homeY);
                homeTargets(num2str(i)) = homePosition;
            end
            
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
            
            % NOTE: plot will reflect new targets on next call to
            % Vision.UpdatePositions()
        end
        
        function directions = GetDirections(obj)
            %GetDirections:
            %   Given Environment.Positions and Environment.Targets,
            %   create and return a map<str(idnum), Burst> containing
            %   burst directions to send to each robot with index idnum
            try
                directions = containers.Map;
                
                for i = 1:obj.Environment.NumRobots
                    % access current position and target from global map
                    position = obj.Environment.Positions(num2str(i));
                    target = obj.Environment.Targets(num2str(i));
                    
                    % determine necessary turn angle
                    % note: CCW is +, CW is -
                    dx = target.Center.X - position.Center.X;
                    dy = target.Center.Y - position.Center.Y;
                    
                    targetAngle = Utils.ArctanInDegrees(dx, dy);
                    currentAngle = position.Heading;
                    turnAngle = targetAngle - currentAngle;
                    
                    % adjust turnAngle if necessary to be within [-180, 180]
                    if turnAngle > 180
                        turnAngle = turnAngle - 360;
                    elseif turnAngle < -180
                        turnAngle = turnAngle + 360;
                    end
                    
                    % determine necessary Burst speed
                    distance = position.Center.Distance(target.Center);
                    
                    if distance < obj.Environment.ConvergenceThreshold
                        speed = 0;
                    elseif distance > obj.Environment.FullSpeedThreshold
                        speed = 100;
                    else
                        speed = 50*(distance - obj.Environment.ConvergenceThreshold)/(obj.Environment.FullSpeedThreshold - obj.Environment.ConvergenceThreshold) + 100;
                    end
                    
                    % construct and save Burst object in directions map
                    burst = Burst(speed, turnAngle);
                    directions(num2str(i)) = burst;
                end
            catch
            end
            % returns completed directions map
        end
        
        function isConverged = IsConverged(obj)
            %IsConverged:
            %   Check to see if all robots are within Environment.ConvergenceThreshold
            %   of their current target point.
            %   Return true if so; else, return false
            try
                isConverged = true;
                
                for i = 1:obj.Environment.NumRobots
                    % access current position and target from global map
                    position = obj.Environment.Positions(num2str(i));
                    target = obj.Environment.Targets(num2str(i));
                    
                    distance = position.Center.Distance(target.Center);
                    
                    if distance > obj.Environment.ConvergenceThreshold
                        % robot i is not converged; return false on break
                        isConverged = false;
                        return;
                    end
                end
            catch
                isConverged = false;
                return;
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
            
            % read and verify CSV format
            rawTargets = csvread(filename);
            Utils.Verify(size(rawTargets, 1) == obj.Environment.NumRobots, Utils.InvalidTargetRowsMessage);
            
            xCoords = rawTargets(:, 1:2:end);
            Utils.Verify(numel(xCoords(xCoords >= 0)) == numel(xCoords) && numel(xCoords(xCoords <= obj.Environment.XAxisSize)) == numel(xCoords), Utils.TargetXOOBMessage);
            
            yCoords = rawTargets(:, 2:2:end);
            Utils.Verify(numel(yCoords(yCoords >= 0)) == numel(yCoords) && numel(yCoords(yCoords <= obj.Environment.YAxisSize)) == numel(yCoords), Utils.TargetYOOBMessage);
            
            Utils.Verify(size(xCoords, 2) == size(yCoords, 2), 'Target CSV contains uneven number of x and y coordinates');
            
            % construct TargetQueue from CSV data
            targetQueue = cell(round(size(rawTargets, 2) / 2), 1);
            
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
            
            % if Environment.GoHome is true, append home targets for robots
            % to end of targetQueue
            if obj.Environment.GoHome
                homeIdx = numel(targetQueue) + 1;
                homeTargets = obj.GetHomeTargets();
                targetQueue{homeIdx} = homeTargets;
            end
            
            % set finished targetQueue
            obj.TargetQueue = targetQueue;
            obj.NumTargets = numel(targetQueue);
            
            % set initial targets
            obj = obj.UpdateTargets();
        end
    end
end

