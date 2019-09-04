%PATHFINDER: sends robots on a configurable path in testing field

% initialize environment settings
environment = Environment();

% initialize webcam tracking
vision = Vision(environment);

% initialize communications
messenger = Messenger(environment);

% initialize plot helper
plotter = Plotter(environment);

% test camera
img = vision.GetSnapshot();
plotter.PlotColorImage(img);

% auto-set threshold

disp(environment);