function bool = IsConverged(goto_matrix, positions, tolerance)
    % check if robots are within acceptable positional tolerance of given waypoints in
    % goto matrix
    bool = true;
    for i = 1:size(goto_matrix, 1)
        dx = goto_matrix(i, 1) - positions(i, 1);
        dy = goto_matrix(i, 2) - positions(i, 2);
        dist = sqrt(dx^2 + dy^2);
        % check on each iteration if the robot is within acceptable
        % tolerance; if not, set flag to false and return; if yes, check
        % rest of robots and return true at end
        if dist > tolerance
            bool = false;
            return;
        end
    end
end