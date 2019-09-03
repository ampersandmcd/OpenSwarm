cam1 = videoinput('winvideo', 1);
triggerconfig(cam1, 'manual');
cam2 = videoinput('winvideo', 2);
triggerconfig(cam2, 'manual');
cam3 = videoinput('winvideo', 3);
triggerconfig(cam3, 'manual');
cam4 = videoinput('winvideo', 4);
triggerconfig(cam4, 'manual');

start(cam1);
start(cam2);
start(cam3);
start(cam4);

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

% Generate stitched panorama of collected images & crop
panorama = Panorama(images);
sz = size(panorama);
x = sz(2);
y = sz(1);
crop_bounds = [0.1*x, 0.15*y, 0.8*x, 0.75*y]; %xmin, ymin, xsize, ysize (note, xmax = xmin + xsize, etc. for y)
pano_crop = imcrop(panorama, crop_bounds);

%Generate black and white binary image to track robots based on threshold
threshold = 0.97;
pano_gray = rgb2gray(pano_crop);
pano_bw = imbinarize(pano_gray, threshold);



imshow(panorama);
figure, imshow(pano_crop);
figure, imshow(pano_bw);

% find and store ordered pairs of white blobs in image
[pano_blobs, num_blobs] = bwlabel(pano_bw);
centers_struct = regionprops(pano_blobs, 'Centroid');
centers = vec2mat(cell2mat(struct2cell(centers_struct)), 2);

%'flip' centers vertically across x axis to align centers with image coord
%system; show x, y pos of centers in scatter plot to assist visualization
centers(:, 2) = size(pano_crop,1) - centers(:, 2);
figure, scatter(centers(:,1), centers(:,2));

% create nx3 array associating the 3 indices of the ordered pairs of each
% robot
neighbors = [];
for i = 1:num_blobs
    x = centers(i, 1);
    y = centers(i, 2);
    nbr_1_idx = 0;
    nbr_1_dist = Inf;
    nbr_2_idx = 0;
    nbr_2_dist = Inf;
    for j = 1:num_blobs
        if j ~= i
            other_x = centers(j, 1);
            other_y = centers(j, 2);
            dx = other_x - x;
            dy = other_y - y;
            dist = sqrt(dx^2 + dy^2);
            if dist < nbr_1_dist
                nbr_2_idx = nbr_1_idx;
                nbr_2_dist = nbr_1_dist;
                nbr_1_idx = j;
                nbr_1_dist = dist;
            elseif dist < nbr_2_dist
                nbr_2_idx = j;
                nbr_2_dist = dist;
            end
        end
    end
    neighbors(i, 1) = i;
    neighbors(i, 2) = nbr_1_idx;
    neighbors(i, 3) = nbr_2_idx;
    disp('s');
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
    disp('wait');
end

% annotate scatter plot of robot centers with deduced position and heading
% arrows
q1 = (robots(:,3) <= 90);
q2 = (robots(:,3) > 90)  .* (robots(:,3) <= 180);
q3 = (robots(:,3) > 180) .* (robots(:,3) <= 270);
q4 = (robots(:,3) > 271) .* (robots(:,3) <= 360);
hold on; 
% See DOC QUIVER
% Use QUIVER to specify the start point (tail of the arrow) and direction based on angle
% q1, q2, q3, and q4 are used to generate four different QUIVER handles (h1, h2, h3, and h4)
% This is necessary for varying colors based on direction
% Based on equations: x = x0 + r*cos(theta), y = y0 + r*sin(theta)
% In the usage below, x0 = robots(:,1), y0 = robots(:,2), theta = robots(:,3) * pi / 180
% Can also specify a scale factor as the last argument to quiver (not specified below)
h1 = quiver(robots(q1 == 1,1), robots(q1 == 1,2), cos(robots(q1 == 1,3) * pi/180), sin(robots(q1 == 1,3) * pi/180));
h2 = quiver(robots(q2 == 1,1), robots(q2 == 1,2), cos(robots(q2 == 1,3) * pi/180), sin(robots(q2 == 1,3) * pi/180)); % sin is negative in 2nd quadrant
h3 = quiver(robots(q3 == 1,1), robots(q3 == 1,2), cos(robots(q3 == 1,3) * pi/180), sin(robots(q3 == 1,3) * pi/180));
h4 = quiver(robots(q4 == 1,1), robots(q4 == 1,2), cos(robots(q4 == 1,3) * pi/180), sin(robots(q4 == 1,3) * pi/180)); % cos is negative in 4th quadrant
% Set colors to red for 1st quadrant, blue for 2nd, green for 3rd, cyan for 4th
% Also, turn scaling off. get(h1) will return additional property-value pairs
set(h1, 'Color', [1 0 0], 'AutoScale', 'on')
set(h2, 'Color', [0 1 0], 'AutoScale', 'on')
set(h3, 'Color', [0 0 1], 'AutoScale', 'on')
set(h4, 'Color', [0 1 1], 'AutoScale', 'on')
% Done plotting
hold off;

                
                

