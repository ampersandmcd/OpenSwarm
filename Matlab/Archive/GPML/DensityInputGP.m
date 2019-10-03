% to eventually make it a function:
% function norm_f = DensityInput(x_axis_sz, y_axis_sz)

% setup %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

x_axis_sz = 1024;
y_axis_sz = 768;
k = 2;
dist = 100;

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

% create function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
R2GP(points, x_axis_sz, y_axis_sz, k, dist);

% normalize function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




