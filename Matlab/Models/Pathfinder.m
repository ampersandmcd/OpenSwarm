%PATHFINDER: sends robots on a configurable path in testing field

% initialize environment settings
environment = Environment();

% initialize plot helper object
plotter = Plotter(environment);

% initialize webcam tracking
vision = Vision(environment, plotter);

% initialize targets and navigation
navigator = Navigator(environment);
navigator = navigator.SetTargetsFromCSV('./test_targets.csv');

% initialize communications
messenger = Messenger(environment, plotter);



%%%%%%%%%%%%%% testing %%%%%%%%%%%%%%%%%%%%%

% update positions of robots in field
vision = vision.UpdatePositions();

% check if robots are converged on targets
flag = navigator.IsConverged();

% get and send directions via UDP
directions = navigator.GetDirections();
messenger.SendDirections(directions);

% update targets map
navigator = navigator.UpdateTargets();

% update positions map
vision = vision.UpdatePositions();

% get and send new directions via UDP
directions = navigator.GetDirections();
messenger.SendDirections(directions);




disp('hello');