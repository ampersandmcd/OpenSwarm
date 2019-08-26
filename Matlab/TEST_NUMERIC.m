%define function
sig = 0.001; % noise variance
syms x y n
x0 = 100;
y0 = 100;
x1 = x_axis_sz-100;
y1 = 100;
x2 = x_axis_sz-100;
y2 = y_axis_sz-100;
x3 = 100;
y3 = y_axis_sz-100;
k = 10000;
f = @(x,y,n) exp(((x-x0).^2 + (y-y0).^2)/(-2*k)) + exp(((x-x1).^2 + (y-y1).^2)/(-2*k)) + exp(((x-x2).^2 + (y-y2).^2)/(-2*k)) + exp(((x-x3).^2 + (y-y3).^2)/(-2*k)) + sig*n

% define sampling and sample function numerically
sampling = 10;
[plotX, plotY] = meshgrid(0:sampling:x_axis_sz, 0:sampling:y_axis_sz);
xTest = reshape([plotX, plotY], [], 2);

% select random training data spread about grid
nTrain = 500;
xTrain = [x_axis_sz*(rand(nTrain,1)), y_axis_sz*(rand(nTrain,1))];
yTrain = feval(f, xTrain(:, 1), xTrain(:, 2), rand(nTrain,1)-0.5);

% regress surface from random training points, then sample at set interval
% to get numerical surface back
points = [xTrain, yTrain];
[x, y, m, s2] = NumericR2GP(points, x_axis_sz, y_axis_sz, sampling);

% concatenate numerical surface into f_vals to send to numeric weighted
% lloyd's algorithm, along with random starting positions of n_robots
f_vals = [x,y,m];
n_robots = 5;
%pts_x = [100;400;900];
pts_x = x_axis_sz * rand(n_robots, 1);
%pts_y = [100;700;100];
pts_y = y_axis_sz * rand(n_robots, 1);

[Px, Py] = NumericWeightedLloydsAlgorithm(pts_x, pts_y, x_axis_sz, y_axis_sz, numIterations, showPlot, f_vals, sampling);