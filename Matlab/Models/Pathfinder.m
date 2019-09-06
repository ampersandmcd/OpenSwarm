%PATHFINDER: sends robots on a configurable path in testing field

% initialize environment settings
environment = Environment();

% initialize plot helper object
plotter = Plotter(environment);

% initialize webcam tracking
vision = Vision(environment, plotter);

% initialize communications
messenger = Messenger(environment, plotter);



% test camera
vision = vision.UpdatePositions();
vision = vision.UpdatePositions();
