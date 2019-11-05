% HILGPC_Standard:
%   Create prior distribution from human-input points.
%   Given confidence threshold, determine necessary points to sample.
%   K-means and TSP the sample points, then update distribution.
%   Converge on centroids of the Voronoi Partition of distribution to
%   achieve coverage.


%% SETUP: OpenSwarm depenencies


% initialize environment settings
environment = Environment(3);

% initialize plot helper object
% plotter = Plotter(environment);

% initialize webcam tracking and purge autofocus
% vision = Vision(environment, plotter);

% initialize navigation
navigator = Navigator(environment, plotter);

% initialize communications
messenger = Messenger(environment, plotter);


%% SETUP: HILGPC dependencies


% run GPML Startup
run('./gpml/gpstartup.m');

% configure HILGPC settings
threshold_uncertainty = 0.1;
recycle_human_prior = true;
human_prior_filename = "prior1.csv";
hilgpc_settings = HILGPC_Settings(threshold_uncertainty, recycle_human_prior, human_prior_filename);

% create HILGPC data object
hilgpc_data = HILGPC_Data(environment, hilgpc_settings);


%% INPUT

if ~recycle_human_prior
    % if not recycling input, get input and save it
    hilgpc_data.GetHumanPrior();
    hilgpc_data.SaveHumanPrior(human_prior_filename);
end

hilgpc_data.ComputeGP();
hilgpc_data.VisualizeGP();


%% PLAN



%% SAMPLE



%% COVER
disp("hi")