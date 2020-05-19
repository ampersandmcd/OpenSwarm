% HILGPC_Bernoulli:
%   Create prior distribution from human-input points.
%   Alter between exploration and exploitation steps following a Bernoulli
%   random variable which favors exploration when uncertainty is high and
%   exploitation when uncertainty is low.


%% SETUP: OpenSwarm depenencies

% initialize environment settings
% note: obtain bounds using Utils/ImageConfiguration.m
isSimulation = true;
bounds = [0, 0, 1, 1];
nRobots = 4;
pad = 0.02;
transformation = [];
maxIteration = 100;
environment = Environment(nRobots, bounds, pad, isSimulation, maxIteration);
environment.Iteration = 1;

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
grid_res = 0.02;
recycle_lofi_prior = true;
recycle_hifi_prior = false;
lofi_prior_filename = "../Data/human_wrong.csv";
hifi_prior_filename = "../Data/VOID.csv";
ground_truth_filename = "../Data/truth.csv";
hilgpc_settings = HILGPC_Settings(s2_threshold, grid_res, recycle_lofi_prior, lofi_prior_filename, recycle_hifi_prior,...
    hifi_prior_filename, ground_truth_filename);

% create HILGPC data object
mf = true; % multi-fidelity? true. single-fidelity? false.
hilgpc_data = HILGPC_Data(environment, plotter, hilgpc_settings, mfgp_matlab, mf);

% create HILGPC actors
% hilgpc_planner = HILGPC_Planner(environment, hilgpc_settings, hilgpc_data);


%% SETUP: More OpenSwarm dependencies

% initialize communications
messenger = Messenger(environment, plotter, hilgpc_data);


%% INPUT
% 
% if ~recycle_lofi_prior
%     % if not recycling human prior, get lofi input and save it
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

% compute starting max variance
max_var_0 = hilgpc_data.MaxS2ValuesNoPrior;

% Initialize other variables to be used on each iteration
targets = containers.Map;
explore = zeros(environment.NumRobots, 1);
prob_explore = zeros(environment.NumRobots, 1);
max_var_point_t = zeros(environment.NumRobots, 2);
max_var_index_t = zeros(environment.NumRobots, 1);
max_var_t = hilgpc_data.MaxS2ValuesNoPrior * ones(environment.NumRobots, 1);
%% ITERATE

% Initialize voronoi partitions
vision.UpdatePositions();

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
    
    % Draw from a Bernoulli to decide explore or exploit for robots on
    % a one-by-one, distributed basis
    for i = 1:environment.NumRobots
        
        % Consider max variance in this cell
        % x,y point of max variance
        max_var_point_t(i, :) = hilgpc_data.MaxS2Matrix(i,:);
        x = max_var_point_t(i, :);
        % index of point of max variance
        max_var_index_t(i, 1) = find(hilgpc_data.TestPoints(:, 1)==x(1) & hilgpc_data.TestPoints(:, 2)==x(2));
        % actual max variance value
        max_var_t(i, 1) = hilgpc_data.TestS2(max_var_index_t(i, 1));
        
        
        % Compute prob_explore and explore for the i-th cell
        % prob_explore(i, 1) = sqrt(min(max_var_t(i, 1) / max_var_0, 1));
        prob_explore(i, 1) = power(min(max_var_t(i, 1) / max_var_0, 1), 2);
        explore(i, 1) = binornd(1, prob_explore(i, 1));
        
        % Decide target point based on explore variable
        if explore(i, 1)
           targets(num2str(i)) = hilgpc_data.MaxS2(num2str(i)); 
        else
           targets(num2str(i)) = hilgpc_data.Centroids(num2str(i));
        end
        
    end
        
    % debug
    disp("Current Max Var by Cell");
    disp(max_var_t');
    disp("Initial Max Var by Cell");
    disp(max_var_0');
    disp("Prob Explore by Cell");
    disp(prob_explore');
    disp("Explore?");
    disp(explore');
    
    % set new targets and force plot of positions, voronoi and explore prob
    environment.Targets = targets;
    plotter.PlotPositions();
    plotter.PlotVoronoi(voronoi);
    plotter.PlotExplore(prob_explore, explore);
    
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
            % plotter.SavePng();
            
            % save current data
            % hilgpc_data.SaveData();
        end
        
        % update positions
        vision.UpdatePositions();
        plotter.PlotVoronoi(voronoi);
       
        % disp("Vaild Frame");

    end
    
    % robots are now converged on this round's targets
    % if this is an exploration step by ANY robot, sample and update the GP
    if sum(explore) > 0
        
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
        targetMatrix = hilgpc_data.TargetsToMatrix();
        
        % ONLY update model with information from robots on an explore step
        update_samples = samples(explore==1);
        update_targets = targetMatrix(explore==1, :);
        hilgpc_data.UpdateModel(update_targets, update_samples);
        
        % Recompute and revisualize model
        hilgpc_data.ComputeMFGP(mfgp_matlab);
        hilgpc_data.VisualizeGP();
    end

    % Compute and visualize loss
    [loss, loss_voronoi] = hilgpc_data.ComputeLoss();
    plotter.PlotLoss(hilgpc_data.Loss);
    fprintf('Loss: %.8d\n', hilgpc_data.Loss(end, 1));
    
    % Visualize loss voronoi
    plotter.PlotLossVoronoiOverTruth(loss_voronoi, hilgpc_data.TestMeshX,...
        hilgpc_data.TestMeshY, hilgpc_data.GroundTruthMeans);
    
    
    % save current figure
    % plotter.SavePng();

    % update environment iteration tracker
    environment.Iterate();
    
    % display iteration
    fprintf('\n\n\n\nIteration: %d\n\n', environment.Iteration);
    
end


% Save recorded samples
% % samples_file = "../Data/collect_MFGP.csv";
% % hilgpc_data.SaveSamples(samples_file);


disp("end")