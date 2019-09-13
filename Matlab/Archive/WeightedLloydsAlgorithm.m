function [Px, Py] = WeightedLloydsAlgorithm(Px,Py, x_axis_sz, y_axis_sz, numIterations, showPlot, f, sampling)
% LLOYDSALGORITHM runs Lloyd's algorithm on the particles at xy positions 
% (Px,Py) within the boundary polygon crs for numIterations iterations
% showPlot = true will display the results graphically.  
% 
% Lloyd's algorithm starts with an initial distribution of samples or
% points and consists of repeatedly executing one relaxation step:
%   1.  The Voronoi diagram of all the points is computed.
%   2.  Each cell of the Voronoi diagram is integrated and the centroid is computed.
%   3.  Each point is then moved to the centroid of its Voronoi cell.
%
% Inspired by http://www.mathworks.com/matlabcentral/fileexchange/34428-voronoilimit
% Requires the Polybool function of the mapping toolbox to run.
%
% Run with no input to see example.  To initialize a square with 50 robots 
% in left middle, run:
%lloydsAlgorithm(0.01*rand(50,1),zeros(50,1)+1/2, [0,0;0,1;1,1;1,0], 200, true)
%
% Made by: Aaron Becker, atbecker@uh.edu
close all
format compact

crs = [0, 0;
        x_axis_sz, 0;
        x_axis_sz, y_axis_sz;
        0, y_axis_sz];

% initialize random generator in repeatable fashion
sd = 20;
rng(sd)



if nargin < 1   % demo mode
    showPlot = true;
    numIterations  = 200;
    xrange = 10;  %region size
    yrange = 5;
    n = 50; %number of robots  (changing the number of robots is interesting)

% Generate and Place  n stationary robots
    Px = 0.01*mod(1:n,ceil(sqrt(n)))'*xrange; %start the robots in a small grid
    Py = 0.01*floor((1:n)/sqrt(n))'*yrange;
    
%     Px = 0.1*rand(n,1)*xrange; % place n  robots randomly
%     Py = 0.1*rand(n,1)*yrange;
    
    crs = [ 0, 0;    
        0, yrange;
        1/3*xrange, yrange;  % a world with a narrow passage
        1/3*xrange, 1/4*yrange;
        2/3*xrange, 1/4*yrange;
        2/3*xrange, yrange;
        xrange, yrange;
        xrange, 0];
    
    for i = 1:numel(Px)  
        while ~inpolygon(Px(i),Py(i),crs(:,1),crs(:,2))% ensure robots are inside the boundary
            Px(i) = rand(1,1)*xrange; 
            Py(i) = rand(1,1)*yrange;
        end
    end
else
    xrange = max(crs(:,1));
    yrange = max(crs(:,2));
    n = numel(Px); %number of robots  
end


% using a cartogram, map field to a uniform-density space
domain = 0:sampling:x_axis_sz;
range = 0:sampling:y_axis_sz;
[xmesh, ymesh] = meshgrid(domain, range);
zmesh = f(xmesh, ymesh);
xfield = reshape(xmesh, [], 1);
yfield = reshape(ymesh, [], 1);
zfield = f(xfield, yfield);
regularizer = 1;

%set up uniform-density for comparison at end before modifying crs
box = crs;
old_Px = Px;
old_Py = Py;

%visualize
figure;
hold on;
surf(xmesh, ymesh, zmesh, 'EdgeColor', 'none');
view([-45, 30]);

syms x y;

cartofield_x = zeros(size(xfield));
cartofield_y = zeros(size(yfield));

for i = 1:size(cartofield_x)
    % integrate wrt x to get xshift based on density
    xi = xfield(i);
    yi = yfield(i);
    xshift = (-1*integral(@(x) f(x, yfield(i)), 0, xfield(i)) + integral(@(x) f(x, yfield(i)), xfield(i), x_axis_sz));
    yshift = (-1*integral(@(y) f(xfield(i), y), 0, yfield(i)) + integral(@(y) f(xfield(i), y), yfield(i), y_axis_sz));
    cartofield_x(i) = xfield(i)-regularizer*xshift;
    cartofield_y(i) = yfield(i)-regularizer*yshift;
end
cartofield = [cartofield_x, cartofield_y];

% get polygon from external edge
bound = boundary(cartofield);
crs = cartofield(bound, :);

% visualize
figure;
hold on;
surf(xmesh, ymesh, zmesh, 'EdgeColor', 'none');
scatter(cartofield(:,1), cartofield(:, 2), 'o');
scatter(crs(:,1), crs(:,2));
plot(polyshape(crs(:,1), crs(:,2)));
axis square;
ax = gca;
ax.XAxisLocation = 'origin';
ax.XLabel.String = 'x';
ax.YAxisLocation = 'origin';
ax.YLabel.String = 'y';
ax.ZLabel.String = 'z';

figure;
hold on;
surf(xmesh, ymesh, zmesh, 'EdgeColor', 'none');
scatter(cartofield(:,1), cartofield(:, 2), 'o');
scatter(crs(:,1), crs(:,2));
plot(polyshape(crs(:,1), crs(:,2)));
axis square;
ax = gca;
ax.XAxisLocation = 'origin';
ax.XLabel.String = 'x';
ax.YAxisLocation = 'origin';
ax.YLabel.String = 'y';
ax.ZLabel.String = 'z';
view([-45, 30]);


%%%%%%%%%%%%%%%%%%%%%%%% VISUALIZATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if showPlot
    figure;
    verCellHandle = zeros(n,1);
    cellColors = cool(n);
    for i = 1:numel(Px) % color according to
        verCellHandle(i)  = patch(Px(i),Py(i),cellColors(i,:)); % use color i  -- no robot assigned yet
        hold on
    end
    pathHandle = zeros(n,1);    
    %numHandle = zeros(n,1);    
    for i = 1:numel(Px) % color according to
        pathHandle(i)  = plot(Px(i),Py(i),'-','color',cellColors(i,:)*.8);
    %    numHandle(i) = text(Px(i),Py(i),num2str(i));
    end
    goalHandle = plot(Px,Py,'+','linewidth',2);
    currHandle = plot(Px,Py,'o','linewidth',2);
    titleHandle = title(['o = Robots, + = Goals, Iteration ', num2str(0)]);
end
%%%%%%%%%%%%%%%%%%%%%%%% END VISUALIZATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    

% Iteratively Apply LLYOD's Algorithm
for counter = 1:numIterations

    %[v,c]=VoronoiLimit(Px,Py, crs, false);
    [v,c]=VoronoiBounded(Px,Py, crs);
    
    if showPlot
        set(currHandle,'XData',Px,'YData',Py);%plot current position
        for i = 1:numel(Px) % color according to
            xD = [get(pathHandle(i),'XData'),Px(i)];
            yD = [get(pathHandle(i),'YData'),Py(i)];
            set(pathHandle(i),'XData',xD,'YData',yD);%plot path position
     %       set(numHandle(i),'Position',[ Px(i),Py(i)]);
        end 
    end
    
    for i = 1:numel(c) %calculate the centroid of each cell
        [cx,cy] = PolyCentroid(v(c{i},1),v(c{i},2));
        cx = min(xrange,max(0, cx));
        cy = min(yrange,max(0, cy));
        if ~isnan(cx) && inpolygon(cx,cy,crs(:,1),crs(:,2))
            Px(i) = cx;  %don't update if goal is outside the polygon
            Py(i) = cy;
        end
    end
    
    if showPlot
        for i = 1:numel(c) % update Voronoi cells
            set(verCellHandle(i), 'XData',v(c{i},1),'YData',v(c{i},2));
        end

        set(titleHandle,'string',['o = Robots, + = Goals, Iteration ', num2str(counter,'%3d')]);
        set(goalHandle,'XData',Px,'YData',Py);%plot goal position
        
        axis equal
        axis([0,xrange,0,yrange]);
        drawnow
%         if mod(counter,50) ==0
%             pause
%             %pause(0.1)
%         end
    end
end

transformed_Px = Px;
transformed_Py = Py;

% finally, invert transformation and obtain coordinates of weighted centers
% using nearest-neighbors inversion
for i=1:size(Px, 1)
    % for each centroid, find indices of four nearest neighbors
    nbrs = [0, 0, 0, 0];
    for j=1:size(cartofield_x, 1)
        if nbrs(1) == 0 | dist(Px(i), cartofield_x(j), Py(i), cartofield_y(j)) < dist(Px(i), cartofield_x(nbrs(1)), Py(i), cartofield_y(nbrs(1)))
            % nearest neighbor, push all else down one
            nbrs(4) = nbrs(3);
            nbrs(3) = nbrs(2);
            nbrs(2) = nbrs(1);
            nbrs(1) = j;
        elseif  nbrs(2)==0 | dist(Px(i), cartofield_x(j), Py(i), cartofield_y(j)) < dist(Px(i), cartofield_x(nbrs(2)), Py(i), cartofield_y(nbrs(2)))
            % second nearest
            nbrs(4) = nbrs(3);
            nbrs(3) = nbrs(2);
            nbrs(2) = j;
        elseif nbrs(3) == 0 | dist(Px(i), cartofield_x(j), Py(i), cartofield_y(j)) < dist(Px(i), cartofield_x(nbrs(3)), Py(i), cartofield_y(nbrs(3)))
            % 3rd nearest
            nbrs(4) = nbrs(3);
            nbrs(3) = j;
        elseif nbrs(4)==0 | dist(Px(i), cartofield_x(j), Py(i), cartofield_y(j)) < dist(Px(i), cartofield_x(nbrs(4)), Py(i), cartofield_y(nbrs(4)))
            % 4th nearest
            nbrs(4) = j;
        end
    end
    % given 4 nearest neighbors in transformed field, average the preimages
    % of each neighbor for the preimage of the weighted
    % centroid
    Px(i) = mean([xfield(nbrs(1)), xfield(nbrs(2)), xfield(nbrs(3)), xfield(nbrs(4))]);
    Py(i) = mean([yfield(nbrs(1)), yfield(nbrs(2)), yfield(nbrs(3)), yfield(nbrs(4))]);
end

% compare to normal voronoi for unweighted shape
[box_Px, box_Py] = LloydsAlgorithm(old_Px, old_Py, box, numIterations, false); 

% visualize weighted centroids of non-uniform density space vs. centroids of
% uniform density space
figure;
hold on;
surf(xmesh, ymesh, zmesh, 'EdgeColor', 'none');
scatter(Px(:), Py(:), '+', 'green');
plot(polyshape(crs(:,1), crs(:,2)));
plot(polyshape(box(:, 1), box(:, 2)));
scatter(box_Px(:), box_Py(:), '+', 'blue');
ax = gca;
ax.XAxisLocation = 'origin';
ax.XLabel.String = 'x';
ax.YAxisLocation = 'origin';
ax.YLabel.String = 'y';
ax.ZLabel.String = 'z';
view([-45, 30]);
grid on;





% END %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% helper methods below %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function d = dist(x1, x2, y1, y2)
    d = sqrt((x1-x2)^2 + (y1-y2)^2);



function [Cx,Cy] = PolyCentroid(X,Y)
% POLYCENTROID returns the coordinates for the centroid of polygon with vertices X,Y
% The centroid of a non-self-intersecting closed polygon defined by n vertices (x0,y0), (x1,y1), ..., (xn?1,yn?1) is the point (Cx, Cy), where
% In these formulas, the vertices are assumed to be numbered in order of their occurrence along the polygon's perimeter, and the vertex ( xn, yn ) is assumed to be the same as ( x0, y0 ). Note that if the points are numbered in clockwise order the area A, computed as above, will have a negative sign; but the centroid coordinates will be correct even in this case.http://en.wikipedia.org/wiki/Centroid
% A = polyarea(X,Y)

Xa = [X(2:end);X(1)];
Ya = [Y(2:end);Y(1)];

A = 1/2*sum(X.*Ya-Xa.*Y); %signed area of the polygon

Cx = (1/(6*A)*sum((X + Xa).*(X.*Ya-Xa.*Y)));
Cy = (1/(6*A)*sum((Y + Ya).*(X.*Ya-Xa.*Y)));

function [V,C]=VoronoiBounded(x,y, crs)
% VORONOIBOUNDED computes the Voronoi cells about the points (x,y) inside
% the bounding box (a polygon) crs.  If crs is not supplied, an
% axis-aligned box containing (x,y) is used.

bnd=[min(x) max(x) min(y) max(y)]; %data bounds
if nargin < 3
    crs=double([bnd(1) bnd(4);bnd(2) bnd(4);bnd(2) bnd(3);bnd(1) bnd(3);bnd(1) bnd(4)]);
end

rgx = max(crs(:,1))-min(crs(:,1)); %range x
rgy = max(crs(:,2))-min(crs(:,2)); %range y
rg = max(rgx,rgy); %range max(x,y)
midx = (max(crs(:,1))+min(crs(:,1)))/2; %midpt x
midy = (max(crs(:,2))+min(crs(:,2)))/2; %midpt y

% add 4 additional edges
xA = [x; midx + [0;0;-5*rg;+5*rg]];
yA = [y; midy + [-5*rg;+5*rg;0;0]];

[vi,ci]=voronoin([xA,yA]);

% remove the last 4 cells
C = ci(1:end-4);
V = vi;
% use Polybool to crop the cells
%Polybool for restriction of polygons to domain.

for ij=1:length(C)
        % thanks to http://www.mathworks.com/matlabcentral/fileexchange/34428-voronoilimit
        % first convert the contour coordinate to clockwise order:
        [X2, Y2] = poly2cw(V(C{ij},1),V(C{ij},2));
        [xb, yb] = polybool('intersection',crs(:,1),crs(:,2),X2,Y2);
        ix=nan(1,length(xb));
        for il=1:length(xb)
            if any(V(:,1)==xb(il)) && any(V(:,2)==yb(il))
                ix1=find(V(:,1)==xb(il));
                ix2=find(V(:,2)==yb(il));
                for ib=1:length(ix1)
                    if any(ix1(ib)==ix2)
                        ix(il)=ix1(ib);
                    end
                end
                if isnan(ix(il))==1
                    lv=length(V);
                    V(lv+1,1)=xb(il);
                    V(lv+1,2)=yb(il);
                    ix(il)=lv+1;
                end
            else
                lv=length(V);
                V(lv+1,1)=xb(il);
                V(lv+1,2)=yb(il);
                ix(il)=lv+1;
            end
        end
        C{ij}=ix;
   
end



