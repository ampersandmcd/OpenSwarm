%PATHFINDER: sends robots on a configurable path in testing field

% initialize environment settings
environment = Environment();

% initialize webcam tracking
vision = Vision(environment);
vision = vision.StartCamera();

% initialize communications
messenger = Messenger(environment);
messenger = messenger.StartUDPTransmitter();

% initialize plot helper
plotter = Plotter();

% test camera
img = vision.GetSnapshot();
plotter.PlotColorImage(img);

% auto-set threshold

disp(environment);