%PATHFINDER: sends robots on a configurable path in testing field

% clean up
clear all;
close all;

% initialize environment
env = Environment();
env = env.StartCamera();
env = env.StartUDPTransmitter();

% initialize plot helper
p = Plotter();

% test camera
img = env.GetSnapshot();
p.PlotColorImage(img);

% auto-set threshold

disp(env);