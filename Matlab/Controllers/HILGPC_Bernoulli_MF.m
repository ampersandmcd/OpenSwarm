% HILGPC_Bernoulli:
%   Create prior distribution from human-input points.
%   Alter between exploration and exploitation steps following a Bernoulli
%   random variable which favors exploration when uncertainty is high and
%   exploitation when uncertainty is low.


%% SETUP: OpenSwarm depenencies

% initialize environment settings
% note: obtain bounds using Utils/ImageConfiguration.m

environment = Environment(4, bounds);
environment.Iteration = 1;

% initialize plot helper object
plotter = Plotter(environment);

% initialize webcam tracking and purge autofocus
vision = Vision(environment, plotter, transformation, bounds);

% initialize navigation
navigator = Navigator(environment, plotter);

% initialize communications
messenger = Messenger(environment, plotter);



%% SETUP: HILGPC dependencies

% run GPML Startup
%run('gpstartup.m');
clear mfgp_matlab
clear mfgp_base
mfgp_matlab = py.importlib.import_module('mfgp_matlab');
mfgp_base = py.importlib.import_module('gaussian_process');
py.importlib.reload(mfgp_matlab);
py.importlib.reload(mfgp_base);

% set random seed for Gaussian reproducibility
rng(100);

% configure HILGPC settings
s2_threshold = 0; % parameter does not apply in this algorithm - only in Threshold algorithm
recycle_lofi_prior = false;
recycle_hifi_prior = false;
lofi_prior_filename = "../Data/prior6_confidence0.8.csv";
hifi_prior_filename = "../Data/collect_hifi.csv";
hilgpc_settings = HILGPC_Settings(s2_threshold, recycle_lofi_prior, lofi_prior_filename, recycle_hifi_prior, hifi_prior_filename);

% create HILGPC data object
hilgpc_data = HILGPC_Data(environment, plotter, hilgpc_settings, mfgp_matlab);

% create HILGPC actors
hilgpc_planner = HILGPC_Planner(environment, hilgpc_settings, hilgpc_data);


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

% initialize explore-exploit random variable where high max uncertainty
% yields low probability of exploitation and low max uncertainty yields
% high probability of exploitation
max_u = hilgpc_data.GetMaxUncertainty();
% k = 1; % tuning parameter greater than 0
prob_explore = 1;

%% ITERATE


while true
    
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
    
    % set targets for this iteration
    targets = containers.Map;
    explore = eye(environment.NumRobots, 1);
    
    for i = 1:environment.NumRobots
        % FOR EACH ROBOT, draw from a Bernoulli to decide explore
        % or exploit
         explore(i,1) = binornd(1, prob_explore);
        
        if explore(i,1)
            % Set target for ith robot to max-S2 point
            targets(num2str(i)) = hilgpc_data.MaxS2(num2str(i));
        else
            % Set target for ith robot to centroid point
            targets(num2str(i)) = hilgpc_data.Centroids(num2str(i));
        end
    
    end
    
    explore
    
    environment.Targets = targets;
    
%     if ~explore
%         % conduct one iteration of Lloyd's Algorithm to circumcenters
%         % (exploit)
%         hilgpc_data.ComputeCentroidsNumerically();
%         targets = hilgpc_data.Centroids;
%         environment.Targets = targets;
%         
%     else
%         % conduct max-uncertainty sample within Voronoi partitions
%         % (explore)
%         hilgpc_data.ComputeCellMaxS2Numerically();
%         %hilgpc_data.ComputeRandomSearch();
%         targets = hilgpc_data.MaxS2;
%         environment.Targets = targets;
%         
%     end
    
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
            plotter.SaveFigure();
            
            % save current data
            hilgpc_data.SaveData();
        end
        
        % update positions
        vision.UpdatePositions();
        plotter.PlotVoronoi(voronoi);
       
               
        disp("Vaild Frame");

    end
    
    % robots are now converged on this round's targets
    % if this is an exploration step, sample and update the GP
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
        targets = hilgpc_data.TargetsToMatrix();
        
        % Keep only the entries of positions and samples for robots that
        % were on an explore step to train the model
        samples = samples(explore == 1)
        targets = targets(explore == 1, :)
            
        % Update model with new samples
        hilgpc_data.UpdateModel(targets, samples);
        
        % Recompute and revisualize model
        hilgpc_data.ComputeMFGP(mfgp_matlab);
        hilgpc_data.VisualizeGP();
    end
    
    % update the probability of explore / exploit linearly
    new_u = hilgpc_data.GetMaxUncertainty()

    % be sure our probability is not > 1
    prob_explore = min(2 * new_u / max_u, 1)
    
    % scale linearly out of maximum observed uncertainty
%     if new_u > max_u
%         max_u = new_u;
%     end

    % compute and visualize loss
    hilgpc_data.ComputeLoss();
    plotter.PlotLoss(hilgpc_data.Loss);

    % update environment iteration tracker
    environment.Iterate();
    
end


% Save recorded samples
% % samples_file = "../Data/collect_MFGP.csv";
% % hilgpc_data.SaveSamples(samples_file);


disp("end")