function points_to_sample = u_descent(train_points, x_axis_sz, y_axis_sz, dx, x, y, m, s2, hyp, threshold);

% goal: iteratively find points with highest uncertainty and sample them to
% obtain a set of points which must be sampled to bring global uncertainty
% below a certain threshold

% save original size of train_points
sz_og = size(train_points, 1);

% setup
run('./GPML/gpstartup.m');      % import GPML
points_to_sample = [];          % store points to sample
[plotX, plotY] = meshgrid(0:dx:x_axis_sz, 0:dx:y_axis_sz);      % generate test points
xTest = reshape([plotX, plotY], [], 2);                         % reshape test points
covfunc = @covSEiso;  % define cov, mean, lik functions for GPML
meanfunc = [];
likfunc = @likGauss;

while max(2*sqrt(s2)) > threshold % keep iterating
    
    % 1) find maximum uncertainty index
    [target_val, target_idx] = max(2*s2);
    points_to_sample = cat(1, points_to_sample, [x(target_idx), y(target_idx)]);
    
    % 2) add predicted mean of this uncertain point to the supposed sample
    % points to convey sense of certainty (note: value does not matter for
    % uncertainty computations)
    row_to_add = [x(target_idx), y(target_idx), m(target_idx)]; 
    mat_to_add = repmat(row_to_add, 10, 1); %add ten rows to train points to convey utter certainty
    train_points = cat(1, train_points, mat_to_add);
    
    % 3) recompute hyp and predictions given new sample
    % training data is given by points
    xTrain = train_points(:, 1:2); % x,y columns of input
    yTrain = train_points(:, 3); % z column of input

    % note: we already have hyp as parameter - just retrain it
    % train hyperparameters
    hyp = minimize(hyp, @gp, -1000, @infGaussLik, meanfunc, covfunc, likfunc, xTrain, yTrain);
    disp(hyp.cov);
    % predict
    [m, s2] = gp(hyp, @infGaussLik, meanfunc, covfunc, likfunc, xTrain, yTrain, xTest);
    
    disp(max(2*sqrt(s2)));
end

% visualize surface with points_to_sample
figure;
hold on
scatter3(xTrain(1:sz_og,1), xTrain(1:sz_og,2), yTrain(1:sz_og), 'black', 'filled'); %ground truth from human
scatter3(xTrain(sz_og+1:end,1), xTrain(sz_og+1:end,2), yTrain(sz_og+1:end), 'red', 'filled'); %supposed predicted truth from newly sampled points

mesh(plotX, plotY, reshape(m, size(plotX, 1), [])); % predicted surface
colormap(gray);

mesh(plotX, plotY, reshape(m-2*sqrt(s2), size(plotX, 1), []), 'FaceColor', [0,1,1], 'EdgeColor', 'blue', 'FaceAlpha', 0.3); % lower bound surface of SD
mesh(plotX, plotY, reshape(m+2*sqrt(s2), size(plotX, 1), []), 'FaceColor', [1,0.5,0], 'EdgeColor', 'red', 'FaceAlpha', 0.3); % lower bound surface of SD

%eplot3([xTest(:, 1), zeros(size(xTest,1), 1)], [xTest(:, 2), zeros(size(xTest,1), 1)], [m, sqrt(s2)], 'black'); % error bars
view(3);
title(sprintf('Human-Input Points in Black, Points to Sample in Red, Threshold = %d', threshold));

end