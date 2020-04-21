% let n be non human loss
% let h be human loss
hloss = h.Loss - min(h.Loss);
nloss = n.Loss - min(n.Loss);
close all;

% plot loss
plot(hloss);    % human = blue
hold on;
plot(nloss);    % non-human = orange

% plot cumulative loss
figure; 
plot(cumsum(hloss));    % human = blue
hold on;
plot(cumsum(nloss));    % non-human = orange

% plot moving mean
figure;
plot(movmean(hloss, 10));    % human = blue
hold on;
plot(movmean(nloss, 10));    % non-human = orange