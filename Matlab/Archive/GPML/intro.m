x = gpml_randn(0.8, 20, 1);
y = sin(3*x) + 0.1*gpml_randn(0.9, 20, 1);
xs = linspace(-3,3, 61)';

meanfunc = [];
covfunc = @covSEiso;
likfunc = @likGauss;

hyp = struct('mean', [], 'cov', [0 0], 'lik', -1);
hyp2 = minimize(hyp, @gp, -100, @infGaussLik, meanfunc, covfunc, likfunc, x, y);
[mu s2] = gp(hyp2, @infGaussLik, meanfunc, covfunc, likfunc, x, y, xs);
  f = [mu+2*sqrt(s2); flipdim(mu-2*sqrt(s2),1)];
  fill([xs; flipdim(xs,1)], f, [7 7 7]/8)
  hold on; plot(xs, mu); plot(x, y, '+')