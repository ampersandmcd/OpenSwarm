% basic GP
% Author: Shaunak D. Bopardikar

clear all
close all

dx = 0.5;
[plotX, plotY] = meshgrid(-10:dx:10, -10:dx:10);
xTest = reshape([plotX, plotY], [], 2);
sig = 0; % noise variance

% Training data
nTrain = 50;
xTrain = 10*(rand(nTrain,2)-0.5);
yTrain = 5*sin(xTrain(:, 1)) + 5*cos(xTrain(:, 2)) + sig*randn(nTrain,1);

% GPML
run('C:\Users\mcdonald\Documents\MATLAB\gpml\gpstartup.m');
%covfunc = @covSEiso;% Uses squared exponential Kernel
covfunc = {'covProd',{'covSEiso','covSEiso'}};
meanfunc = @meanConst;
ell = 1;
sf = 1;
hyp.cov = log([ell, ell; sf, sf]);
hyp.mean = 0;
likfunc = @likGauss;
sn = 0.01;
hyp.lik = log(sn);

% Train hyperparameters
hyp = minimize(hyp, @gp, -1000, @infExact, meanfunc, covfunc, likfunc, xTrain, yTrain);

% predict on test points
[m, s2] = gp(hyp, @infExact, meanfunc, covfunc, likfunc, xTrain, yTrain, xTest);

figure;
hold on
scatter3(xTrain(:,1), xTrain(:,2), yTrain); %ground truth
mesh(plotX, plotY, reshape(m, size(plotX, 1), []), gray(reshape(m, size(plotX, 1), []))); % predicted surface
%eplot3([xTest(:, 1), zeros(size(xTest,1), 1)], [xTest(:, 2), zeros(size(xTest,1), 1)], [m, s2], 'b'); % error bars
mesh(plotX, plotY, reshape(m-sqrt(s2), size(plotX, 1), []), autumn(reshape(m-sqrt(s2), size(plotX, 1), []))); % lower bound of SD
mesh(plotX, plotY, reshape(m+sqrt(s2), size(plotX, 1), []), winter(reshape(m-sqrt(s2), size(plotX, 1), []))); % lower bound of SD


view(3);
