% General Parameters to set
num_robots = 4;
% Set superimposed field coordinate limits to 800x800
x_axis_sz = 1024;
y_axis_sz = 768;
dx = 10; % sampling size for predicted light surface mesh

% set discrete command delay
delay = 2;

% Start and configure cameras
imaqreset;
cam1 = videoinput('winvideo', 1);
triggerconfig(cam1, 'manual');
start(cam1);

% flush photos to allow camera to autofocus
for i = 1:5
    getsnapshot(cam1);
end

% Create and open udp server to send commands to Arduinos
try
    fclose(instrfindall);
catch
end
u = udp('10.10.10.255', 8080);
fopen(u);

% Create and open udp listeners to receive light levels from Arduinos
udpr = {};
udpr{1} = udp('10.10.10.255', 'RemotePort', 8080, 'LocalPort', 8001, 'Timeout', 0.01);
udpr{2} = udp('10.10.10.255', 'RemotePort', 8080, 'LocalPort', 8002, 'Timeout', 0.01);
udpr{3} = udp('10.10.10.255', 'RemotePort', 8080, 'LocalPort', 8003, 'Timeout', 0.01);
udpr{4} = udp('10.10.10.255', 'RemotePort', 8080, 'LocalPort', 8004, 'Timeout', 0.01);
% udpr{5} = udp('10.10.10.255', 'RemotePort', 8080, 'LocalPort', 8005, 'Timeout', 0.01);
for i = 1:size(udpr,2)
    fopen(udpr{i});
end

% initialize dummy counter variable for ID association
counter = 1;

% configure waypoint matrix manually, or call MakeWaypoints
% waypoint_matrix = [50, 50, 90;
%                    x_axis_sz-50, y_axis_sz-50, 90;
%                    x_axis_sz-50, 50, 90;
%                   ];
%               
% waypoint_matrix(:, :, 2) = [400, 400, 90;
%                             500, 400, 90;
%                             450, 500, 90;
%                            ];
%                        
% waypoint_matrix(:, :, 3) = waypoint_matrix(:, :, 1);
num_waypoints = 4;
go_home = true;
pose = false;
% waypoint_matrix = MakeWaypoints(num_waypoints, num_robots, x_axis_sz, y_axis_sz, go_home, pose);

% configure tolerances for convergence
dist_tolerance = 40;
theta_tolerance = 180; %180 nullifies directional "pose" checking, instead checking only positional convergence

% initalize plots
positions = [];
fig_graph = figure;
ax_graph = gca;
% pause(5);
tic;

% initialize light level capture
lightmap = [];

% given 3D waypoint_matrix consisting of multiple 2D goto matrices,
% along with tolerances for achieving each waypoint, successively send
% commands until robots converge on each waypoint, then send next.
for i = 1:size(waypoint_matrix, 3)
    goto_matrix = waypoint_matrix(:, :, i);
    positions = Locate(cam1, x_axis_sz, y_axis_sz, counter, positions, num_robots);
    while ~IsPosed(goto_matrix, positions, dist_tolerance, theta_tolerance)
        % continue converging on this step of waypoint_matrix
        
        % get current position of each robot
        positions = Locate(cam1, x_axis_sz, y_axis_sz, counter, positions, num_robots); % get positions
        
        % tell each robot where to go on next "burst"
        SendCmd(goto_matrix, positions, u);
        
        % don't overload UDP commands to robots
        pause(delay);
        
        % get current light levels of each robot and save into lightmap
        templight = zeros(num_robots, 3);
        templight(:, 1:2) = positions(:, 1:2); % get x,y coords of each robot
        try
            templight(:, 3) = GetLight(udpr); % associate light level with x,y 
        catch
            templight(:, 3) = zeros(size(templight(:, 3)));
        end
        templight(templight(:,3)==0, :) = []; % drop zero-valued light levels (even in dark conditions, LDR will not return zero value; zero value is "junk" data
        lightmap = cat(1, lightmap, templight);
        
        % visualize current locations of each robot
        PlotLocations(positions, goto_matrix, x_axis_sz, y_axis_sz, ax_graph);
        
        % visualize lightmap
        PlotLightmap(lightmap, x_axis_sz, y_axis_sz, ax_graph)
        
        % bookkeeping
        counter = counter + 1;
        disp(counter);
        toc;
        tic;
    end
end

% regress predicted lightmap surface
R2GP(lightmap, x_axis_sz, y_axis_sz, dx);