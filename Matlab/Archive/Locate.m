function positions = Locate(camera, x_axis_sz, y_axis_sz, counter, previous_positions, num_robots)
    im1 = getsnapshot(camera);
    x_sz = size(im1, 2);
    y_sz = size(im1, 1);
    cropped = imcrop(im1, [x_sz/2 - x_axis_sz/2, y_sz/2 - y_axis_sz/2, x_axis_sz, y_axis_sz]);
%     imshow(cropped);
    
    %Generate black and white binary image to track robots based on threshold
    threshold = 0.7;
    im_grey = rgb2gray(cropped);
    im_bw = imbinarize(im_grey, threshold);
    % remove blobs of extraneous pixels in bw image
    min_num_pixels = 5;
    im_bw = bwareaopen(im_bw, min_num_pixels);

    % imshow(panorama);
    % figure, imshow(pano_crop);
    % figure, imshow(pano_bw);

    % find and store ordered pairs of white blobs in image
    [im_blobs, num_blobs] = bwlabel(im_bw);
    if num_blobs ~= num_robots * 3
        % this is a problem; we need to bail & hope for better luck on the
        % next loop
        positions = previous_positions;
        disp('WARNING: mismatched blob count');
        return;
    end
    centers_struct = regionprops(im_blobs, 'Centroid');
    centers = vec2mat(cell2mat(struct2cell(centers_struct)), 2);

    % 'flip' centers vertically across x axis to align centers with image coord
    % system; show x, y pos of centers in scatter plot to assist visualization
    centers(:, 2) = y_axis_sz - centers(:, 2);

    % create nx3 array associating the 3 indices of the ordered pairs of each
    % robot
    neighbors = [];
    for i = 1:num_blobs
        x = centers(i, 1);
        y = centers(i, 2);
        nbr_idx = 0;
        nbr_dist = Inf;
        nbr_2_idx = 0;
        nbr_2_dist = Inf;
        for j = 1:num_blobs
            if j ~= i
                other_x = centers(j, 1);
                other_y = centers(j, 2);
                dx = other_x - x;
                dy = other_y - y;
                dist = sqrt(dx^2 + dy^2);
                if dist < nbr_dist
                    nbr_2_idx = nbr_idx;
                    nbr_2_dist = nbr_dist;
                    nbr_idx = j;
                    nbr_dist = dist;
                elseif dist < nbr_2_dist
                    nbr_2_idx = j;
                    nbr_2_dist = dist;
                end
            end
        end
        neighbors(i, 1) = i;
        neighbors(i, 2) = nbr_idx;
        neighbors(i, 3) = nbr_2_idx;
    end

    neighbors = sort(neighbors, 2);
    groups = unique(neighbors, 'rows');
    robots = [];

    for i = 1:size(groups, 1)
        % get 3 anchor point coordinates of each robot
        p1 = groups(i, 1);
        p2 = groups(i, 2);
        p3 = groups(i, 3);

        x1 = centers(p1, 1);
        y1 = centers(p1, 2);
        x2 = centers(p2, 1);
        y2 = centers(p2, 2);
        x3 = centers(p3, 1);
        y3 = centers(p3, 2);

        % calculate center of each robot and put x coord into robots(i, 1), y
        % coord into robots(i, 2)
        x_mean = mean([x1, x2, x3]);
        y_mean = mean([y1, y2, y3]);
        robots(i, 1) = x_mean;
        robots(i, 2) = y_mean;

        % find short side of isosceles triangle and use vector from its
        % midpoint to the opposite point of the triangle to determine heading
        side12 = norm([x1-x2, y1-y2]);
        side23 = norm([x2-x3, y2-y3]);
        side31 = norm([x3-x1, y3-y1]);

        midpoint = 0;
        farpoint = 0;
        if side12 == min([side12, side23, side31])
            midpoint = [mean([x1, x2]), mean([y1, y2])];
            farpoint = [x3, y3];
        elseif side23 == min([side12, side23, side31])
            midpoint = [mean([x2, x3]), mean([y2, y3])];
            farpoint = [x1, y1];
        elseif side31 == min([side12, side23, side31])
            midpoint = [mean([x3, x1]), mean([y3, y1])];
            farpoint = [x2, y2];
        end

        % calculate heading vector of robot from short leg midpoint through
        % opposite point and determine angle of vector in degrees, then store
        % in robots(i, 3)
        heading_vec = farpoint - midpoint;
        theta = 0;
        if heading_vec(1) >=0 && heading_vec(2) >= 0
            % vector is in 1st quadrant, atan is positive
            theta = atan(heading_vec(2)/heading_vec(1));
        elseif heading_vec(1) <=0 && heading_vec(2) >= 0
            % vector is in 2nd quadrant, atan is negative
            theta = pi + atan(heading_vec(2)/heading_vec(1));
        elseif heading_vec(1) <=0 && heading_vec(2) <= 0
            % vector is in 3rd quadrant, atan is positive
            theta = pi + atan(heading_vec(2)/heading_vec(1));
        elseif heading_vec(1) >=0 && heading_vec(2) <= 0
            % vector is in 4th quadrant, atan is negative
            theta = 2 * pi + atan(heading_vec(2)/heading_vec(1));
        end
        theta = rad2deg(theta);
        robots(i, 3) = theta;
    end
    
    % now, return new positions
    if counter==1
        % this is the first time the Locate function is called
        % auto-associate robot id's by least distance from origin
        robots(:, 4) = robots(:, 1).^2 + robots(:, 2).^2;
        robots = sortrows(robots, 4); % 4th column gives distance from origin as calculated above
        positions = robots(:, 1:3); % drop 4th column when returning
        % now, robots in positions array will be sorted with first row
        % having lowest x position and last row having highest x position
    else
        % this is *not* the first time the Locate function is called
        % associate robot id's to previous positions of each robot, using
        % nearest-neighbors algorithm between current positions and
        % previous positions
        
        % ensure that we haven't "lost" any robots
        if (size(robots, 1)==size(previous_positions, 1))
            for i = 1:size(robots, 1)
                x = robots(i, 1);
                y = robots(i, 2);
                nbr_idx = i;
                nbr_dist = Inf;
                for j = 1:size(previous_positions, 1)
                    other_x = previous_positions(j, 1);
                    other_y = previous_positions(j, 2);
                    dx = other_x - x;
                    dy = other_y - y;
                    dist = sqrt(dx^2 + dy^2);
                    if dist < nbr_dist
                        nbr_idx = j;
                        nbr_dist = dist;
                    end
                end
                % swap robot id row i with neighbor from last position
                robots([i, nbr_idx], :) = robots([nbr_idx, i], :);
            end
            % now, robots should remain in proper id row throughout entire
            % script
            positions = robots;
        else
            % we "lost" a robot, or gained one; bail
            positions = previous_positions;
            disp('WARNING: mismatched robot count');
        end
    end
end

                
                

