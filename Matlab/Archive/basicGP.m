% basic GP
% Author: Shaunak D. Bopardikar

clear all
close all

dx = 0.5;
xTest = 0:dx:10; % only for plotting
sig = 0; % noise variance

% Training data
nTrain = 10;
xTrain = 10*rand(nTrain,1);
yTrain = 5*sin(xTrain) + sig*randn(nTrain,1);

% GPML
run('C:\Users\mcdonald\Documents\MATLAB\gpml\gpstartup.m');
covfunc = @covSEiso;% Uses squared exponential Kernel
meanfunc = @meanConst;
ell = 1;
sf = 1;
hyp.cov = log([ell; sf]);
hyp.mean = 0;
likfunc = @likGauss;
sn = 0.01;
hyp.lik = log(sn);

% Train hyperparameters
hyp = minimize(hyp, @gp, -1000, @infExact, meanfunc, covfunc, likfunc, xTrain, yTrain);

% predict on test points
[m, s2] = gp(hyp, @infExact, meanfunc, covfunc, likfunc, xTrain, yTrain, xTest(:));

figure;
errorbar(xTest, m, sqrt(s2));
hold on
plot(xTrain, yTrain, 'ok', xTest, 5*sin(xTest), '--r')
