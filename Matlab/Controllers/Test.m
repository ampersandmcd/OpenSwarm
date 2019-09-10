%Test: check functionalities of various Actors and Models

%% SETUP 


% initialize environment settings
environment = Environment(3);

% initialize plot helper object
plotter = Plotter(environment);

% initialize webcam tracking
vision = Vision(environment, plotter);

% initialize targets and navigation
navigator = Navigator(environment, plotter);
navigator = navigator.SetTargetsFromCSV('../Data/test_path.csv');

% initialize communications
messenger = Messenger(environment, plotter);




%% ACTION


% update positions of robots in field
vision.UpdatePositions();

% check if robots are converged on targets
flag = navigator.IsConverged();

% get and send directions via UDP
directions = navigator.GetDirections();
messenger.SendDirections(directions);

% update targets map
navigator.UpdateTargets();

% update positions map
vision.UpdatePositions();

% get and send new directions via UDP
directions = navigator.GetDirections();
messenger.SendDirections(directions);

% test send halt command
messenger.SendHalt();



