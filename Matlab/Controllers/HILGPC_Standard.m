% HILGPC_Standard:
%   Create prior distribution from human-input points.
%   Given confidence threshold, determine necessary points to sample.
%   K-means and TSP the sample points, then update distribution.
%   Converge on centroids of the Voronoi Partition of distribution to
%   achieve coverage.


%% SETUP

% run GPML Startup
run('./gpml/gpstartup.m');

% configure OpenSwarm tracking

% initialize environment settings
environment = Environment(3);

% initialize plot helper object
plotter = Plotter(environment);

% initialize webcam tracking and purge autofocus
% vision = Vision(environment, plotter);

% initialize navigation
navigator = Navigator(environment, plotter);

% initialize communications
messenger = Messenger(environment, plotter);



% configure HILGPC

% configure HILGPC settings
threshold_uncertainty = 0.1;
hilgpc_settings = HILGPC_Settings(threshold_uncertainty);

% create HILGPC data object
% hilgpc_data = HILGPC_Data(environment, hilgpc_settings);




%% INPUT

% hilgpc_data.GetHumanPrior();
hilgpc_data.ComputeGP();
hilgpc_data.VisualizeGP();



%% PLAN



%% SAMPLE



%% COVER
disp("hi")