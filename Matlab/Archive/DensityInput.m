% to eventually make it a function:
% function norm_f = DensityInput(x_axis_sz, y_axis_sz)

% setup %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

x_axis_sz = 1024;
y_axis_sz = 768;

% gather points %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ax = axes('Position', [0.1, 0.2, 0.8, 0.7]);
xlim([0, x_axis_sz]);
ylim([0, y_axis_sz]);
title("Click areas of interest"); 
box on;
h = uicontrol('Style', 'PushButton', ...
                    'String', 'Done', ...
                    'Callback', 'delete(gcbf)');
points = [];
i = 1;
while ishandle(h) % record points of interest before user clicks "Done" button
   if size(points, 1) > 0
      scatter(ax, points(:, 1), points(:, 2));
      xlim([0, x_axis_sz]);
      ylim([0, y_axis_sz]);
      title("Click areas of interest"); 
      box on;
   end
   try 
      [points(i, 1), points(i, 2)] = ginput(1);
   catch
       % if user closes figure with "Done" button, exit loop
       close all;
   end
   i = i+1;
end
% truncate last entry from clicking "Done" button
points = points(1:end-1, :);
disp(points);


% gather lengthscale info %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

input = inputdlg('Enter space-separated lengthscale parameters for each bump function, or enter one value to apply to all bump functions');
lengthscale = str2num(cell2mat(input(1)));

if size(lengthscale) == 1
    % make lengthscale vector same size as points matrix to simplify later
    % code
    lengthscale(1:size(points, 1)) = lengthscale(1);
elseif size(lengthscale) ~= size(points, 1)
    % error - take first number
    disp("Error: lengthscale mismatch; taking first number and applying globally");
    lengthscale(1:size(points, 1)) = lengthscale(1);
% else: each point will have individual lengthscale param
end

% create function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define global function to be composed upon
syms x y
f = @(x, y) 0;

% loop through and create bump function at each point, composing to global
for i = 1:size(points, 1);
    % define local squared exponential cov function from current point
    g = @(x, y) exp(-0.5/lengthscale(i)^2 * ((x-points(i, 1))^2 + (y-points(i, 2))^2));
    % concatenate this bump function to global function
    f = @(x, y) f(x, y) + g(x, y);
end

% normalize function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% look for max of function starting at middle of field
inv_f = @(x,y) -1*f(x,y); % must invert to use fminsearch

% find min iteratively by starting min search at various points (minimizes
% likelyhod of getting stuck at local min)
% start at center
spacing = 50;
[min_xy, min_z] = fminsearch(@(x) inv_f(x(1),x(2)), [x_axis_sz/2, y_axis_sz/2]);
for x0 = 1:spacing:x_axis_sz
    for y0 = 1:spacing:y_axis_sz
        [temp_min_xy, temp_min_z] = fminsearch(@(x) inv_f(x(1),x(2)), [x0, y0]);
        if temp_min_z < min_z
            min_z = temp_min_z;
        end
    end
end

max_z = -min_z; % need to invert after fminsearch to get max
disp([min_xy, max_z]);
norm_f = @(x,y) 1/max_z*f(x,y); % normalize

% vizualize normalized function
fsurf(norm_f, [0, x_axis_sz, 0, y_axis_sz]);
title("User generated density function");


