function [m_new, s_new]=gaussian_estimator(m,s,arm_current,reward,sigma)
%reward = measurement inputs from human (2 boundaries)
%sigma = sn from sensor - assume zero so that variance drops to zero upon
%precomputation sample
%arm current=arm from which  the measurement is from - the indexed point as
%in cov_mat
%m = mean prior matrix
%s = cov_mat matrix

%reward is vector of samples at each point

%first stage: iterate through all human points and pass upper and lower
%bound in reward

%second: look at diagonal entries, find max, recompute with sn=0 at that
%point, iterate
no_of_samples=length(reward);

phi=zeros(size(m));
phi(arm_current)=1;

q = sum(reward)*phi/sigma^2 + inv(s)*m;

s_inv_new = no_of_samples*(phi*phi')/sigma^2 + inv(s);

s_new = inv(s_inv_new);


m_new = s_new*q;