% General Parameters to set
num_robots = 3;
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

% Create goto matrix for robot formation
goto_matrix = [200, 200, 90;
               800, 200, 90;
               500, 600, 90;
               ];

% Create positions array to store robot positions; create positions figure
% on which to plot robot positions
positions = [];
fig_graph = figure;
ax_graph = gca;
tic;

for counter = 1:1000
    % update positions array: on first loop, assign id's to robots by
    % ascending x position; on loops thereafter, assign id's based on
    % nearest previous position neighbor
    positions = Locate(cam1, x_axis_sz, y_axis_sz, counter, positions, num_robots);
    
    % show derived positions + headings
    PlotLocations(positions, goto_matrix, x_axis_sz, y_axis_sz, ax_graph);
    
    % determine & send commands
    SendCmd(goto_matrix, positions, u)
    % time successive iterations to get sense of feedback rate
    disp(counter);
    toc;
    tic;
    pause(0.5);
end

% clean up
hold off;
stop(cam1);
fclose(u);