function waypoint_matrix = MakeWaypoints(num_waypoints, num_robots, x_axis_sz, y_axis_sz, go_home, pose)
    waypoint_matrix = [];    
    figure; 
    axis([0, x_axis_sz, 0, y_axis_sz]);
    hold on;
    for i = 1:num_robots
        [x_path, y_path] = ginput(num_waypoints);
        waypoint_matrix(i, 1, :) = x_path;
        waypoint_matrix(i, 2, :) = y_path;
        plot(x_path, y_path);
    end
    hold off;
    
    if go_home == true
        % following pathfinding, send robots to home position along x axis
        left_bound = 100;
        right_bound = x_axis_sz - 100;
        lower_bound = 100;
        gap = (right_bound - left_bound) / (num_robots - 1);
        for i = 1:num_robots
            waypoint_matrix(i, 1, num_waypoints + 1) = left_bound + gap * (i - 1);
            waypoint_matrix(i, 2, num_waypoints + 1) = lower_bound;
        end
    end
    
    pose_angles = [];
    if pose == true
        % make robots turn to pose heading at each waypoint (need to set
        % theta_tolerance to desired constant in Pathfinder.m)
        for i = 1:num_waypoints
            pose_angles(i) = input(sprintf("Enter pose angle %d", i));
        end
        waypoint_matrix(:, 3, :) = pose_angles;
    else
        % ignore pose heading at each waypoint -- just go to waypoint (need
        % to set theta_tolerance to 180 in Pathfinder.m
        waypoint_matrix(:, 3, :) = 0;
    end
end