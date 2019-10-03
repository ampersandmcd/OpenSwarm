% basic GP
% Author: Shaunak D. Bopardikar

close all

% generating function
sig = 0.1; % noise variance
syms x y n
f = @(x,y,n) 5*sin(x) + 5*cos(y) + sig*n;
%f = @(x,y,n) x.^2 + y.^2 + sig*n;

dx = 0.5;
[plotX, plotY] = meshgrid(-10:dx:10, -10:dx:10);
xTest = reshape([plotX, plotY], [], 2);

% Training data
nTrain = 50;
xTrain = 10*(rand(nTrain,2)-0.5);
yTrain = feval(f, xTrain(:, 1), xTrain(:, 2), randn(nTrain,1));

% GPML
run('../gpml/gpstartup.m');
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
scatter3(xTrain(:,1), xTrain(:,2), yTrain, 'black'); %ground truth
mesh(plotX, plotY, reshape(m, size(plotX, 1), [])); % predicted surface
colormap(gray);

mesh(plotX, plotY, reshape(m-sqrt(s2), size(plotX, 1), []), 'FaceColor', [0,1,1], 'EdgeColor', 'blue', 'FaceAlpha', 0.3); % lower bound surface of SD
mesh(plotX, plotY, reshape(m+sqrt(s2), size(plotX, 1), []), 'FaceColor', [1,0.5,0], 'EdgeColor', 'red', 'FaceAlpha', 0.3); % lower bound surface of SD

%eplot3([xTest(:, 1), zeros(size(xTest,1), 1)], [xTest(:, 2), zeros(size(xTest,1), 1)], [m, sqrt(s2)], 'black'); % error bars

view(3);
