% COMMTEST.M
% 
% Test UDP broadcast to a particular robot to ensure communication
% infrastructure is properly functioning

%% CONFIGURATION

message =  '<start><3>90,100</3><end>';

%% SETUP

% initialize environment settings
environment = Environment(2, bounds);

% initialize plot helper object
plotter = Plotter(environment);

% initialize communications
messenger = Messenger(environment, plotter);

%% EXECUTION

for i = 1:10
    messenger.SendMessage(message);
end
