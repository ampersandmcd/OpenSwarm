% HILGPC_Bernoulli:
%   Create prior distribution from human-input points.
%   Alter between exploration and exploitation steps following a Bernoulli
%   random variable which favors exploration when uncertainty is high and
%   exploitation when uncertainty is low.


%% SETUP: OpenSwarm depenencies

% initialize environment settings
% note: obtain bounds using Utils/ImageConfiguration.m
isSimulation = true;
bounds = [0, 0, 710, 290];
maxIteration = 100;
environment = Environment(8, bounds, isSimulation, maxIteration);
environment.Iteration = 1;

% set random seed for start position reproducibility
rng(300);

% initialize plot helper object
plotter = Plotter(environment);

% initialize webcam tracking and purge autofocus
vision = Vision(environment, plotter, transformation, bounds);

% initialize navigation
navigator = Navigator(environment, plotter);


%% SETUP: HILGPC dependencies

% run GPML Startup
%run('gpstartup.m');
clear mfgp_matlab
clear mfgp_base
mfgp_matlab = py.importlib.import_module('mfgp_matlab');
mfgp_base = py.importlib.import_module('gaussian_process');
py.importlib.reload(mfgp_matlab);
py.importlib.reload(mfgp_base);

% configure HILGPC settings
s2_threshold = 0; % parameter does not apply in this algorithm - only in Threshold algorithm
recycle_lofi_prior = false;
recycle_hifi_prior = false;
lofi_prior_filename = "../Data/four_corners_human.csv";
hifi_prior_filename = "../Data/VOID.csv";
ground_truth_filename = "../Data/four_corners_50.csv";
hilgpc_settings = HILGPC_Settings(s2_threshold, recycle_lofi_prior, lofi_prior_filename, recycle_hifi_prior,...
    hifi_prior_filename, ground_truth_filename);

% create HILGPC data object
hilgpc_data = HILGPC_Data(environment, plotter, hilgpc_settings, mfgp_matlab);

% create HILGPC actors
hilgpc_planner = HILGPC_Planner(environment, hilgpc_settings, hilgpc_data);


%% SETUP: More OpenSwarm dependencies

% initialize communications
messenger = Messenger(environment, plotter, hilgpc_data);


%% INPUT
% 
% if ~recycle_lofi_prior
%     if not recycling human prior, get lofi input and save it
%     hilgpc_data.GetLofiPrior();
%     hilgpc_data.SavePrior(lofi_prior_filename, "low");
% end

% if ~recycle_hifi_prior
%     % if not recycling sample prior, get hifi input and save it
%     hilgpc_data.GetHifiPrior();
%     hilgpc_data.SavePrior(hifi_prior_filename, "high");
% end

hilgpc_data.ComputeMFGP(mfgp_matlab);
hilgpc_data.VisualizeGP();

% initialize explore-exploit random variable where high max uncertainty
% yields low probability of exploitation and low max uncertainty yields
% high probability of exploitation
max_u = hilgpc_data.GetMaxUncertainty();
% k = 1; % tuning parameter greater than 0
prob_explore = 1;

%% ITERATE

% Initialize voronoi partitions
vision.UpdatePositions();
hilgpc_data.UpdateVoronoi();

while environment.Iteration <= environment.MaxIteration
    
    % update current positions of robots in field
    vision.UpdatePositions();
    
    % skip this iteration if robot positions are invalid / not updated
    % properly by vision module
    if ~vision.Updated()
        continue
    end
    
    % Compute current centroids and max-variances
    hilgpc_data.ComputeCentroidsNumerically();
    hilgpc_data.ComputeCellMaxS2Numerically();
    
    % Plot current voronoi partitions and positions
    voronoi = hilgpc_data.VoronoiCells;
    plotter.PlotVoronoi(voronoi);
    
    % Set targets for this iteration
    targets = containers.Map;
    
    % Draw from a Bernoulli to decide explore
    % or exploit for ALL ROBOTS
    explore = binornd(1, prob_explore);
    
    if explore
        % Set target for ith robot to max-S2 point
        targets = hilgpc_data.MaxS2;
    else
        % Set target for ith robot to centroid point
        targets = hilgpc_data.Centroids;
    end
        
    % debug
    fprintf("Explore?: %f\n", explore);
    
    % set new targets and force plot
    environment.Targets = targets;
    plotter.PlotPositions();
    plotter.PlotVoronoi(voronoi);
    
    % targets are now properly set    
    % until robots are converged on this round of targets, get and send directions
    while(~navigator.IsConverged())

        % if positions up to date, get and send directions via UDP
        if vision.Updated
            
            directions = navigator.GetDirections();
            messenger.SendDirections(directions);

            % wait for directions to execute
            pause(environment.Delay);
            
            % read back feedback
            messenger.ReadMessage();
            
            % save current figure
            plotter.SavePng();
            
            % save current data
            % hilgpc_data.SaveData();
        end
        
        % update positions
        vision.UpdatePositions();
        plotter.PlotVoronoi(voronoi);
       
        % disp("Vaild Frame");

    end
    
    % robots are now converged on this round's targets
    % if this is an exploration step, sample and update the GP
    if explore > 0
        
        % Repeat until robots all send back a valid sample
        while ~messenger.Received
            
            % send null directions to prompt robot feedback
            halt = navigator.GetHaltDirections();
            messenger.SendDirections(halt);
            
            % wait for directions to execute
            pause(environment.Delay);
            
            % read back feedback
            messenger.ReadMessage();
        end
        
        % Now, messenger.LastMessage contains an array of latest feedbacks
        samples = messenger.LastMessage;
        
        % Get positions for easy manipulation
        targets = hilgpc_data.TargetsToMatrix();
        
        % Update model with new samples
        hilgpc_data.UpdateModel(targets, samples);
        
        % Recompute and revisualize model
        hilgpc_data.ComputeMFGP(mfgp_matlab);
        hilgpc_data.VisualizeGP();
    end
    
    % Update the probability of explore / exploit linearly
    new_u = hilgpc_data.GetMaxUncertainty();
    fprintf('New Max Uncertainty: %f\n', new_u);

    % Be sure our probability is not > 1
    prob_explore = min(new_u / max_u, 1);
    fprintf('Prob Explore: %f\n', prob_explore);

    % Compute and visualize loss
    [loss, loss_voronoi] = hilgpc_data.ComputeLoss();
    plotter.PlotLoss(hilgpc_data.Loss);
    fprintf('Loss: %d\n', hilgpc_data.Loss(end, 1));
    
    % Visualize loss voronoi
    plotter.PlotLossVoronoiOverTruth(loss_voronoi, hilgpc_data.TestMeshX,...
        hilgpc_data.TestMeshY, hilgpc_data.GroundTruthMeans);
    
    
    % save current figure
    plotter.SavePng();
    
    % Update Voronoi partition if this was NOT an explore step
    if ~explore
       hilgpc_data.UpdateVoronoi();
       fprintf('Repartitioned');
    end

    % update environment iteration tracker
    environment.Iterate();
    
    % display iteration
    fprintf('\n\n\n\nIteration: %d\n\n', environment.Iteration);
    
end


% Save recorded samples
% % samples_file = "../Data/collect_MFGP.csv";
% % hilgpc_data.SaveSamples(samples_file);


disp("end")