%TestVision: check functionalities of Vision class

%% SETUP 


% initialize environment settings
environment = Environment(3, bounds);

% initialize plot helper object
plotter = Plotter(environment);

% initialize webcam tracking
vision = Vision(environment, plotter, transformation, bounds);

vision.GetColorImage();
vision.GetBWImage();
vision.UpdatePositions();
