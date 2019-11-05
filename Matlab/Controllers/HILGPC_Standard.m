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

% set random seed for Gaussian reproducibility
rng(100);

% configure HILGPC settings
s2_threshold = 0.25; % variance < 0.25 ==> std_dev < 0.5
recycle_human_prior = true;
human_prior_filename = "prior1_confidence2.csv";
hilgpc_settings = HILGPC_Settings(s2_threshold, recycle_human_prior, human_prior_filename);

% create HILGPC data object
hilgpc_data = HILGPC_Data(environment, hilgpc_settings);

% create HILGPC actors
hilgpc_planner = HILGPC_Planner(environment, hilgpc_settings, hilgpc_data);


%% INPUT

if ~recycle_human_prior
    % if not recycling prior, get input and save it
    hilgpc_data.GetHumanPrior();
    hilgpc_data.SaveHumanPrior(human_prior_filename);
end

hilgpc_data.ComputeGP();
hilgpc_data.VisualizeGP();


%% PLAN

% determine necessary points to reduce uncertainty below threshold and
% visualize the higher-confidence result
hilgpc_planner.ReduceUncertainty();
hilgpc_data.VisualizeGP();


% cluster hilgpc_data.SamplePoints (the points needed to reduce max(s2))
% into k = environment.NumRobots clusters, and create a TargetQueue for
% robots to follow based on a TSP tour of each cluster
target_queue = hilgpc_planner.ClusterTSPTour();

% set navigator.TargetQueue to prepare for sampling phase
navigator.TargetQueue = target_queue;


%% SAMPLE



%% COVER



disp("end")