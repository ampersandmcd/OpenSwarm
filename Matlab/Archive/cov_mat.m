function [loc, S0] = cov_mat(og_points, ell, sf)

n = size(og_points, 1);
loc = zeros(n^2, 2);
for i=1:n
    for j=1:n
        loc((i-1)*n+j,1)=i;
        loc((i-1)*n+j,2)=j;
    end
end


lambda = 1/(2 * ell^2) ; %ell from gp

dist = zeros(n^2, 2);
rho = zeros(n^2, 2);
for i=1:length(loc(:,1))
    for j=1:length(loc(:,1))
        dist(i,j)=sqrt(sum((loc(i,:)-loc(j,:)).^2));
        rho(i,j)=exp(-lambda*(dist(i,j)^2));
    end
end


sigma_0 = sf; %sf from gp
S0 = sigma_0*rho; %scale matrix by sf noise

end