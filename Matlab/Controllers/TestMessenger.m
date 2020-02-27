% TestMessenger: test functionality of messenger class

%% SETUP: OpenSwarm depenencies

% initialize environment settings
% note: obtain bounds using Utils/ImageConfiguration.m
environment = Environment(4, bounds);

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
    
    message = '<start><1>0,100</1><2>0,0</2><3>0,0</3><4>0,0</4><end>';
    
    % send test message
    messenger.SendMessage(message);

    % wait
    pause(environment.Delay);

    % read received messages
    messenger.ReadMessage();
    
    if messenger.Received
       for i = 1:environment.NumRobots
           fprintf("Robot %d : %d\n", i, messenger.LastMessage(i,1));
       end
    end
end