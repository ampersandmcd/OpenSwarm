%Test: check functionalities of various Actors and Models

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
