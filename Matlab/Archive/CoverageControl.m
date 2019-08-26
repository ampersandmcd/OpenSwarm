% General Parameters to set
num_robots = 3;
num_iterations = 100;

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

% configure field boundaries as polygon
pgon = [0, 0;
        x_axis_sz, 0;
        x_axis_sz, y_axis_sz;
        0, y_axis_sz];

% % initalize plots
% positions = [];
% fig_graph = figure;
% ax = gca;
% pause(5);
% tic;

% calculate next Lloyd iteration one at a time, wait for robots to converge
% on this Lloyd iteration, then calculate next Lloyd iteration, and so on.
for i = 1:num_iterations
    positions = Locate(cam1, x_axis_sz, y_axis_sz, counter, positions, num_robots);
    [goto_matrix(:, 1), goto_matrix(:, 2)] = LloydsAlgorithm(positions(:,1), positions(:,2), pgon, 1, true);
    goto_matrix(:, 3) = 90;
    SendCmd(goto_matrix, positions, u);
    counter = counter + 1;
    disp(sprintf("Lloyd Iteration #%d", i));
    toc;
    tic;
    pause(0.5);
end