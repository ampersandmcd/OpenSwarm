function [train_points, og_points, confidence] = LightmapInput(x_axis_sz, y_axis_sz, dx, max_clicks)
% setup %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% x_axis_sz = 1024;
% y_axis_sz = 768;
% dx = 50 % grid spacing between gridlines

% gather points %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fig = figure('units', 'normalized', 'outerposition', [0,0,1,1]);
h = uicontrol(fig, 'Style', 'PushButton', ...
                    'String', 'Done', ...
                    'Callback', 'close(gcbf)');
ax = axes('Position', [0.1, 0.2, 0.8, 0.7]);
xlim([0, x_axis_sz]);
ylim([0, y_axis_sz]);
title(sprintf("Click to indicate light level on testbed from scale of 1-%d, where 0 = no information, 1 = darkest and %d = brightest", max_clicks, max_clicks)); 
box on;
grid(ax, 'on')
ax.XTick = 0:dx:x_axis_sz;
ax.YTick = 0:dx:y_axis_sz;
daspect([1,1,1]);
colormap(jet);
colorbar;
ax.CLim = [0, max_clicks];
points = [];
while ishandle(h) % record points of interest before user clicks "Done" button
    try 
      % get input points
      [temp_x, temp_y] = ginput(1);
      % round input points to nearest grid
      x_round_targets = 0:dx:x_axis_sz;
      y_round_targets = 0:dx:y_axis_sz;
      temp_x = interp1(x_round_targets, x_round_targets, temp_x, 'nearest');
      temp_y = interp1(y_round_targets, y_round_targets, temp_y, 'nearest');
      if size(points, 1) > 0 & size(points(points(:,1) == temp_x & points(:,2) == temp_y, :), 1) > 0
          % element already exists in points; bump up count until max_clicks,
          % then roll over back to 0
          points(points(:,1) == temp_x & points(:,2) == temp_y, 3) = mod(points(points(:,1) == temp_x & points(:,2) == temp_y, 3) + 1, max_clicks + 1);
          % if we roll back to zero, delete this entry from the list of
          % points
          if points(points(:,1) == temp_x & points(:,2) == temp_y, 3) == 0
              points(points(:,1) == temp_x & points(:,2) == temp_y, :) = [];
              disp(points(:,:));
          end
      else
          points = cat(1, points, [temp_x, temp_y, 1]);
      end
    catch
       % if user closes figure with "Done" button, exit loop
    end
   
    if size(points, 1) > 0
        try
            scatter(ax, points(:, 1), points(:, 2), 50, points(:,3), 'filled');
            colorbar;
            ax.CLim = [0, max_clicks];
            xlim([0, x_axis_sz]);
            ylim([0, y_axis_sz]);
            title(sprintf("Click to indicate light level on testbed from scale of 1-%d, where 0 = no information, 1 = darkest and %d = brightest", max_clicks, max_clicks)); 
            box on;
            grid(ax, 'on')
            ax.XTick = 0:dx:x_axis_sz;
            ax.YTick = 0:dx:y_axis_sz; 
            daspect([1,1,1]);
        catch
            % if user closes figure with "Done" button, exit loop
        end
    end
end
% truncate last entry from clicking "Done" button
points = points(1:end-1, :);

% gather uncertainty info %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

confidence = inputdlg('Enter confidence in your measurements, on a scale from 0 to 100');
confidence = str2num(confidence{1});
uncertainty = 100-confidence;

% change points to capture uncertainty by duplicating input point and
% moving points to capture upper & lower bounds of confidence interval
og_points = points; % save original inputs

%1) duplicate each entry in points
sz = size(points, 1);
train_points = cat(1, points, points);
%2) modify first half of points to lower confidence bound
train_points(1:sz, 3) = train_points(1:sz, 3) - (uncertainty / 100) .* train_points(1:sz, 3);
%3) modify second half of points to upper confidence bound
train_points(sz+1:end, 3) = train_points(sz+1:end, 3) + (uncertainty / 100) .* train_points(sz+1:end, 3);

% normalize point light levels between 0 and 1, with 1 click being no
% light (corresponding to 0) and max_clicks being bright (corresponding to
% 1)
train_points(:,3) = (train_points(:,3) - min(train_points(:,3))) ./ (max(train_points(:,3)) - min(train_points(:,3)));
og_points(:,3) = (og_points(:,3) - min(og_points(:,3))) ./ (max(og_points(:,3)) - min(og_points(:,3)));
end
