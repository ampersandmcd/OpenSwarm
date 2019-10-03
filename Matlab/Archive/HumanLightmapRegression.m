x_axis_sz = 1024;
y_axis_sz = 768;
dx = 50;
max_clicks = 5;
threshold = 0.05; % value representing +/- decimal acceptable uncertainty [values are normalized to range between 0-1]
num_robots = 5; % for k-means clustering

%note: points from LightMap input are duplicate from upper & lowc.close aller bounds
% [train_points, og_points, confidence] = LightmapInput(x_axis_sz, y_axis_sz, dx, max_clicks);
[x, y, m, s2, hyp] = HumanNumericR2GP(train_points, x_axis_sz, y_axis_sz, dx, confidence);

% determine points to sample to lower uncertainty below threshold
points_to_sample = u_descent(train_points, x_axis_sz, y_axis_sz, dx, x, y, m, s2, hyp, threshold);

% k-means cluster points to sample and visualize
idx = kmeans(points_to_sample, num_robots);
figure;
gscatter(points_to_sample(:,1), points_to_sample(:,2), idx);
xlim([0, x_axis_sz]);
ylim([0, y_axis_sz]);
title('k-Means Clustering of Points to Sample');
