function bool = IsPosed(goto_matrix, positions, dist_tolerance, theta_tolerance)
    % check if robots are within acceptable positional tolerance of given waypoints in
    % goto matrix AND within acceptable directional tolerance of given
    % angles in goto matrix
    bool = IsConverged(goto_matrix, positions, dist_tolerance);
    if ~bool
        % robots aren't even at the right positions
        return;
    else
        for i = 1:size(goto_matrix, 1)
            dt = abs(goto_matrix(i, 3) - positions(i, 3));
            % adjust difference in theta to be within [0, 180] interval
            if dt > 180
                dt = 360 - dt;
            end
            % check if heading is within acceptable tolerance; if not,
            % return false; if yes, keep iterating and check other robots
            % and return true at end
            if dt > theta_tolerance
                bool = false;
                return;
            end
        end
end