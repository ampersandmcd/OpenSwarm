function numeric_data = GetLight(udpr)
    num_robots = numel(udpr);
    raw_data = cell(num_robots, 1);
    for i = 1:num_robots
        level = '0';
        % get most recent light level reading from each robot
        while udpr{i}.BytesAvailable > 0
            level = fgetl(udpr{i});
        end
        % set light level into return matrix
        raw_data{i} = level;
        % flush UDP stream to clean up
        % flushinput(udpr{i});            
    end
    % convert to numeric from string cell array
    S = sprintf('%s ', raw_data{:});
    numeric_data = sscanf(S, '%f');
    
    % returns numeric_data, column vector of light levels from each robot
end