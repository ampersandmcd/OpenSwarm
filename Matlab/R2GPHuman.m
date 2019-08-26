function R2GP(points, x_axis_sz, y_axis_sz, k, dist)
% Author: Shaunak D. Bopardikar
% Modified: Andrew McDonald
dx = y_axis_sz / sqrt(k) / sqrt(size(points, 1)); %scale artifically generated 0s based on how many input points are given
[plotX, plotY] = meshgrid(0:dx:x_axis_sz, 0:dx:y_axis_sz);
xTest = reshape([plotX, plotY], [], 2);

% training data is given by points
xTrain = points;
xBlanks = [];
for i=1:size(xTest, 1)
    flag = true;
    for j=1:size(points, 1)
        d = sqrt((points(j,1)-xTest(i,1))^2 + (points(j,2)-xTest(i,2))^2);
        if d < dist
            % then, we don't want this row as a zero in xTrain
            flag = false;
        end
    end
    if flag == true
        xBlanks = cat(1, xBlanks, xTest(i, :));
    end
end
xTrain = cat(1, xTrain, xBlanks);
yTrain = ones(size(points, 1), 1);
yBlanks = zeros(size(xBlanks, 1), 1);
yTrain = cat(1, yTrain, yBlanks);
nTrain = size(xTrain, 1);

% GPML
run('startup.m');
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
end
