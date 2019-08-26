% General Parameters to set
num_robots = 5;
num_iterations = 100;
tolerance = 40; % in px

% Set superimposed field coordinate limits to 800x800
x_axis_sz = 1024;
y_axis_sz = 768;

% Start and configure cameras
cam1 = videoinput('winvideo', 1);
triggerconfig(cam1, 'manual');
start(cam1);

% Create and open udp server to send commands to Arduinos
u = udp('10.10.10.255', 8080);
fopen(u);

% initialize dummy counter variable for ID association
counter = 1;

% declare density function over space
% gaussian
x0 = 100;
y0 = 100;
x1 = x_axis_sz-100;
y1 = 100;
x2 = x_axis_sz-100;
y2 = y_axis_sz-100;
x3 = 100;
y3 = y_axis_sz-100;
k = 10000;
f = @(x,y) exp(((x-x0).^2 + (y-y0).^2)/(-2*k)) + exp(((x-x1).^2 + (y-y1).^2)/(-2*k)) + exp(((x-x2).^2 + (y-y2).^2)/(-2*k)) + exp(((x-x3).^2 + (y-y3).^2)/(-2*k))

% visualize density function over space
domain = 0:1:x_axis_sz;
range = 0:1:y_axis_sz;
[xfield, yfield] = meshgrid(domain, range);
z = f(xfield, yfield);
mesh(xfield, yfield, z);

% declare numerical sampling density for numerical integration in
% weightedlloyd
sampling = 10;

% create empty positions matrix for first iteration
positions = [];

% start timer
tic;

% get initial positions of each robot
positions = Locate(cam1, x_axis_sz, y_axis_sz, counter, positions, num_robots);

% run weighted Lloyd's algorithm to obtain weighted Voronoi centroids for
% goto_matrix
[goto_matrix(:, 1), goto_matrix(:, 2)] = WeightedLloydsAlgorithm(positions(:,1), positions(:,2), x_axis_sz, y_axis_sz, 50, false, f, sampling);
goto_matrix(:, 3) = 90;

% get axes to track robots on
ax = gca;
title({'$\rho (x,y)=e^{\frac{(x-x_0)^2+(y-y_0)^2}{2\sigma ^2}} + e^{\frac{(x-x_1)^2+(y-y_1)^2}{2\sigma ^2}} + e^{\frac{(x-x_2)^2+(y-y_2)^2}{2\sigma ^2}} + e^{\frac{(x-x_3)^2+(y-y_3)^2}{2\sigma ^2}}$', '$\sigma=10^4, x_0=100, y_0=100, x_1=924, y_1=100, x_2=924, y_2=668, x_3=100, y_3=668$, Field Size = 1024x768, nRobots = 5'}, 'Interpreter', 'latex', 'FontSize', 14);
alpha 0.5;

% run convergence loop until robots are converged on weighted voronoi
% centroids
while ~IsConverged(goto_matrix, positions, tolerance)
    positions = Locate(cam1, x_axis_sz, y_axis_sz, counter, positions, num_robots);
    PlotLocations(positions, goto_matrix, x_axis_sz, y_axis_sz, ax);
    SendCmd(goto_matrix, positions, u);
    disp(sprintf("Iteration #%d", counter));
    counter = counter + 1;
    toc;
    tic;
    pause(0.5);
end