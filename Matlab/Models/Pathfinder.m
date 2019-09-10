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



% test
vision = vision.UpdatePositions();
flag = navigator.IsConverged();
directions = navigator.GetDirections();
% successfully returned directions map
navigator = navigator.UpdateTargets();
% successfully updated targets
vision = vision.UpdatePositions();
%successfully reset positions
directions = navigator.GetDirections();
%try to reset directions map
disp('hello');