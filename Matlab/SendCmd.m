function f = SendCmd(goto_matrix, positions, u)
    % goto_matrix should contain (x, y, angle) in each row for desired
    % destinations of robots
    % u should be udp object to write to
    if size(goto_matrix) ~= size(positions)
        % we've got a problem; bail
        disp('WARNING: goto_matrix dimension mismatch with positions matrix');
    end
    
    cmd_matrix = [];
    
    for i = 1:size(goto_matrix, 1)
        dx = goto_matrix(i, 1) - positions(i, 1);
        dy = goto_matrix(i, 2) - positions(i, 2);
        dist = sqrt(dx^2+dy^2);
               
        % calculate trajectory angle to follow to goto point
        current_ang = positions(i, 3);
        goto_ang = rad2deg(atan(dy/dx));
        if dy > 0 && dx > 0
            % 1st quadrant vector, no change
        elseif dy > 0 && dx < 0
            % 2nd quadrant vector, add 180
            goto_ang = goto_ang + 180;
        elseif dy < 0 && dx < 0
            % 3rd quadrant vector, add 180
            goto_ang = goto_ang + 180;
        elseif dy < 0 && dx > 0
            % 4th quadrant vector, add 360
            goto_ang = goto_ang + 360;
        end
        
        dt = 0;
        %calculate speed and necessary turn angle
        speed = 0;
        if dist > 100
            % move at full speed
            speed = 100;
            % calculate necessary turn angle
            dt = goto_ang - current_ang;
        elseif dist > 30 && dist < 100
            % slow down upon approach to target
            speed = 100*(-((100-dist)/100)^3 + 1);
            % calculate necessary turn angle
            dt = goto_ang - current_ang;
        elseif dist < 30 
            % stop and turn into final "pose" position; consider self
            % arrived
            speed = 0;
            dt = goto_matrix(i, 3) - current_ang;
            if abs(dt) < 20
                % at correct ordered pair, in correct (enough) pose position; stop
                % turning
                dt = 0;
            end
        end
        

        
        % note: dt = deltatheta is positive for left turns, negative for
        % right turns (ccw, cw)
        if dt > 180
            dt = dt - 360;
        elseif dt < -180
            dt = dt + 360;
        end
        
        % the command for robot i needs the arguments [angle_to_turn,
        % speed_to_move]
        cmd_matrix(i, 1) = dt;
        cmd_matrix(i, 2) = speed;
    end
    
    % now, generate string command to send via UDP
    cmd = '<start>';
    for i = 1:size(cmd_matrix, 1)
        % send commands with format <ID>angle,speed</ID>
        cmd = strcat(cmd, sprintf('<%d>%d,%d</%d>', i, round(cmd_matrix(i, 1)), round(cmd_matrix(i, 2)), i));
    end
    cmd = strcat(cmd, '<end>');
    
    % send command over UDP
    disp(cmd);
    fwrite(u, cmd);
end