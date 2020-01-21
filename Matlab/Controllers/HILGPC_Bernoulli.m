% HILGPC_Bernoulli:
%   Create prior distribution from human-input points.
%   Alter between exploration and exploitation steps following a Bernoulli
%   random variable which favors exploration when uncertainty is high and
%   exploitation when uncertainty is low.


%% SETUP: OpenSwarm depenencies

% initialize environment settings
environment = Environment(4, bounds);

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
run('gpstartup.m');

% set random seed for Gaussian reproducibility
rng(100);

% configure HILGPC settings
s2_threshold = 0; % parameter does not apply in this algorithm - only in Threshold algorithm
recycle_human_prior = true;
human_prior_filename = "../Data/prior4_confidence0.8.csv";
hilgpc_settings = HILGPC_Settings(s2_threshold, recycle_human_prior, human_prior_filename);

% create HILGPC data object
hilgpc_data = HILGPC_Data(environment, plotter, hilgpc_settings);

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

% initialize explore-exploit random variable where high max uncertainty
% yields low probability of exploitation and low max uncertainty yields
% high probability of exploitation
max_u = hilgpc_data.GetMaxUncertainty();
k = 1; % tuning parameter greater than 0
prob_exploit = exp(-k * max_u);


%% ITERATE


while true
    
    % update current positions of robots in field
    vision.UpdatePositions();
    % skip this iteration if robot positions are invalid / not updated
    % properly by vision module
    if ~vision.Updated()
        continue
    end
    
    % draw from a Bernoulli with prob_exploit where 1 => exploitation step
    % and 0 => exploration step
    exploit = binornd(1, prob_exploit);
    
    
    % force test
    %
     exploit = true;
    %
    %
    
    if exploit
        % conduct one iteration of Lloyd's Algorithm to circumcenters
        % (exploit)
        hilgpc_data.ComputeCentroidsNumerically();
        targets = hilgpc_data.Centroids;
        environment.Targets = targets;
        
    else
        % conduct max-uncertainty sample within Voronoi partitions
        % (explore)
        hilgpc_data.ComputeCellMaxS2();
        targets = hilgpc_data.MaxS2;
        environment.Targets = targets;
        
    end
    
    % targets are now properly set    
    % until robots are converged on this round of targets, get and send directions
    while(~navigator.IsConverged())

        % if positions up to date, get and send directions via UDP
        if vision.Updated
            
            directions = navigator.GetDirections();
            messenger.SendDirections(directions);

            % wait for directions to execute
            pause(environment.Delay);
        end
        
        % update positions
        vision.UpdatePositions();

    end
    
    % robots are now converged on this round's targets
    % if this is an exploration step, sample and update the GP
    if ~exploit
        % take samples from each robot
        % add sample and sample location to GP sample points and sample means
        % add sample and sample location to GP train points and train means
        % recompute the GP
        % visualize new GP
        % update the probability of explore / exploit
    end
    
    % update environment iteration tracker
    environment.Iterate();
    
end


disp("end")