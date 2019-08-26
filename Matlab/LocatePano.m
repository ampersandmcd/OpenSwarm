function robots = LocatePano(cameras, x_axis_sz, y_axis_sz, counter, previous_positions)
    cam1 = cameras(1);
    cam2 = cameras(2);
    cam3 = cameras(3);
    cam4 = cameras(4); 
    
    im1 = getsnapshot(cam1);
    im2 = getsnapshot(cam2);
    im3 = getsnapshot(cam3);
    im4 = getsnapshot(cam4);

    %flip images 3 & 4 due to upside-down orientation
    im3 = flip(im3, 2);
    im3 = flip(im3, 1);
    im4 = flip(im4, 2);
    im4 = flip(im4, 1);

    stop(cam1);
    stop(cam2);
    stop(cam3);
    stop(cam4);

    images = {im1, im2, im3, im4};

    % montage(images);

    % Generate stitched panorama of collected images & crop to 800x800px
    panorama = Panorama(images);
    sz = size(panorama);
    x = sz(2);
    y = sz(1);
    crop_bounds = [0.5 * x - x_axis_sz / 2, 0.5 * y - y_axis_sz / 2, x_axis_sz, y_axis_sz]; %xmin, ymin, xsize, ysize (note, xmax = xmin + xsize, etc. for y)
    pano_crop = imcrop(panorama, crop_bounds);

    %Generate black and white binary image to track robots based on threshold
    threshold = 0.95;
    pano_gray = rgb2gray(pano_crop);
    pano_bw = imbinarize(pano_gray, threshold);
    % remove blobs of extraneous pixels in bw image
    min_num_pixels = 5;
    pano_bw = bwareaopen(pano_bw, min_num_pixels);

    % imshow(panorama);
    % figure, imshow(pano_crop);
    % figure, imshow(pano_bw);

    % find and store ordered pairs of white blobs in image
    [pano_blobs, num_blobs] = bwlabel(pano_bw);
    centers_struct = regionprops(pano_blobs, 'Centroid');
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
    
    if counter==1
        % this is the first time the Locate function is called
        % auto-associate robot id's by x coordinate from lowest to highest
        robots = sortrows(robots);
        % now, robots in positions array will be sorted with first row
        % having lowest x position and last row having highest x position
    else
        % this is *not* the first time the Locate function is called
        % associate robot id's to previous positions of each robot, using
        % nearest-neighbors algorithm between current positions and
        % previous positions
        for i = 1:size(previous_positions, 1)
            x = previous_positions(i, 1);
            y = previous_positions(i, 2);
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
    end
end

                
                

