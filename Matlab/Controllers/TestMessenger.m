% TestMessenger: test functionality of messenger class

%% SETUP: OpenSwarm depenencies

% initialize environment settings
% note: obtain bounds using Utils/ImageConfiguration.m
environment = Environment(2, bounds);

% initialize plot helper object
plotter = Plotter(environment);

% initialize webcam tracking and purge autofocus
vision = Vision(environment, plotter, transformation, bounds);

% initialize navigation
navigator = Navigator(environment, plotter);

% initialize communications
messenger = Messenger(environment, plotter);

%% TEST
while true
    
    message = '<start><1>15,100</1><2>15,100</2><end>';
    
    % send test message
    messenger.SendMessage(message);

    % wait
    pause(environment.Delay);

    % read received messages
    messenger.ReadMessage();
end