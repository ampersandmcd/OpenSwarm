% HILGPC_Standard:
%   Create prior distribution from human-input points.
%   Given confidence threshold, determine necessary points to sample.
%   K-means and TSP the sample points, then update distribution.
%   Converge on centroids of the Voronoi Partition of distribution to
%   achieve coverage.


%% SETUP

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



% configure HILGPC setup

% configure HILGPC settings
hilgpc_settings = HILGPC_Settings(10, 0.15);

% create HILGPC data object
hilgpc_data = HILGPC_Data(environment, hilgpc_settings);


%% ACTION
disp("hi")