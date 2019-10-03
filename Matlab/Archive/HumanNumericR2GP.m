function [x, y, m, s2, hyp] = HumanNumericR2GP(points, x_axis_sz, y_axis_sz, dx, confidence)
% Author: Shaunak D. Bopardikar
% Modified: Andrew McDonald
[plotX, plotY] = meshgrid(0:dx:x_axis_sz, 0:dx:y_axis_sz);
xTest = reshape([plotX, plotY], [], 2);

% training data is given by points
xTrain = points(:, 1:2); % x,y columns of input
yTrain = points(:, 3); % z column of input
nTrain = size(xTrain, 1);

% GPML
run('./GPML/gpstartup.m');
%covfunc = @covSEiso;% Uses squared exponential Kernel
covfunc = @covSEiso;
meanfunc = [];
ell = 100;
sf = 1;
hyp.cov = log([ell; sf]);
hyp.mean = [];
likfunc = @likGauss;
sn=1;
hyp.lik = log(sn);

% Train hyperparameters
hyp = minimize(hyp, @gp, -1000, @infGaussLik, meanfunc, covfunc, likfunc, xTrain, yTrain);
disp(hyp.cov);

% % readjust likelihood value based on confidence input after hyp
% % optimization before prediction
% %temp_lik = exp(hyp.lik);
% %temp_lik = temp_lik * (101-confidence) / 100;
% temp_lik = (101-confidence) / 100;
% hyp.lik = log(temp_lik);
% disp(hyp);

% predict on test points
[m, s2] = gp(hyp, @infGaussLik, meanfunc, covfunc, likfunc, xTrain, yTrain, xTest);

figure;
hold on
scatter3(xTrain(:,1), xTrain(:,2), yTrain, 'black', 'filled'); %ground truth
mesh(plotX, plotY, reshape(m, size(plotX, 1), [])); % predicted surface
colormap(gray);

mesh(plotX, plotY, reshape(m-2*sqrt(s2), size(plotX, 1), []), 'FaceColor', [0,1,1], 'EdgeColor', 'blue', 'FaceAlpha', 0.3); % lower bound surface of SD
mesh(plotX, plotY, reshape(m+2*sqrt(s2), size(plotX, 1), []), 'FaceColor', [1,0.5,0], 'EdgeColor', 'red', 'FaceAlpha', 0.3); % lower bound surface of SD

%eplot3([xTest(:, 1), zeros(size(xTest,1), 1)], [xTest(:, 2), zeros(size(xTest,1), 1)], [m, sqrt(s2)], 'black'); % error bars

view(3);
title(sprintf('Regressed Lightmap with Confidence = %d / 100', confidence));

%produce return values, structured as [x,y,z, var] where x = xTest x coord, y =
%xTest y coord, z = mu predicted value & s2 = variance at each point
x = xTest(:, 1);
y = xTest(:, 2);
%m = m;
%s2 = s2;
%hyp = hyp;
end

