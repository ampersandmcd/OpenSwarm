% HILGPC_Bernoulli:
%   Create prior distribution from human-input points.
%   Alter between exploration and exploitation steps following a Bernoulli
%   random variable which favors exploration when uncertainty is high and
%   exploitation when uncertainty is low.


%% SETUP: OpenSwarm depenencies

% initialize environment settings
% note: obtain bounds using Utils/ImageConfiguration.m
% TEMP manually declare bounds [x,y,width,height]
%bounds = [100, 100, 1000, 500];
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

% set random seed for Gaussian reproducibility
rng(100);

% configure HILGPC settings
s2_threshold = 0; % parameter does not apply in this algorithm - only in Threshold algorithm
recycle_lofi_prior = false;
recycle_hifi_prior = false;
lofi_prior_filename = "";
hifi_prior_filename = "";
hilgpc_settings = HILGPC_Settings(s2_threshold, recycle_lofi_prior, lofi_prior_filename, recycle_hifi_prior, hifi_prior_filename);

% create HILGPC data object
hilgpc_data = HILGPC_Data(environment, plotter, hilgpc_settings, []);

%% INPUT


%% ITERATE


while true
    
    % update current positions of robots in field
    vision.UpdatePositions();
    % skip this iteration if robot positions are invalid / not updated
    % properly by vision module
    if ~vision.Updated()
        continue
    end
    
    hilgpc_data.ComputeRandomSearch();
    environment.Targets = hilgpc_data.RandomSample;
    
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
        end
        
        % update positions
        vision.UpdatePositions();

    end
    
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
    positions = hilgpc_data.PositionsToMatrix();
    
    % Update model with new samples
    hilgpc_data.UpdateModel(positions, samples);
    
    % update environment iteration tracker
    environment.Iterate();
    
end


% Save recorded samples
samples_file = "../Data/collect_MFGP_2.csv";
hilgpc_data.SaveSamples(samples_file);


disp("end")