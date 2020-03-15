classdef Voronoi
    %VORONOI Helper class to define voronoi methods, including partitioning
    % and computation of Lloyd's Algorithm
    properties
        
    end
    
    methods(Static)
        function [Px, Py] = LloydsAlgorithmCentroidsCartogram(Px,Py, crs, numIterations)
            % LLOYDSALGORITHMCENTROID runs Lloyd's algorithm on the particles at xy positions
            % (Px,Py) within the boundary polygon crs for numIterations iterations
            %
            % Lloyd's algorithm (centroid) starts with an initial distribution of samples or
            % points and consists of repeatedly executing one relaxation step:
            %   1.  The Voronoi diagram of all the points is computed.
            %   2.  Each cell of the Voronoi diagram is integrated and the centroid is computed.
            %   3.  Each point is then moved to the centroid of its Voronoi cell.
            %
            % Inspired by http://www.mathworks.com/matlabcentral/fileexchange/34428-voronoilimit
            % Requires the Polybool function of the mapping toolbox to run.
            %
            % Originally sourced from Aaron Becker: https://www.mathworks.com/matlabcentral/fileexchange/41507-lloydsalgorithm-px-py-crs-numiterations-showplot
            % Modified by Andrew McDonald for use in OpenSwarm
            
            % set range
            xrange = max(crs(:,1));
            yrange = max(crs(:,2));
            n = numel(Px); %number of robots
            
            % Iteratively Apply LLYOD's Algorithm
            for counter = 1:numIterations
                
                [vertices,cells]=Voronoi.VoronoiBounded(Px,Py, crs);
                
                for i = 1:numel(cells) %calculate the centroid of each cell
                    [cx,cy] = Voronoi.PolyCentroid(vertices(cells{i},1),vertices(cells{i},2));
                    cx = min(xrange,max(0, cx));
                    cy = min(yrange,max(0, cy));
                    if ~isnan(cx) && inpolygon(cx,cy,crs(:,1),crs(:,2))
                        Px(i) = cx;  %don't update if goal is outside the polygon
                        Py(i) = cy;
                    end
                end
            end
        end
        
        function [Px, Py, R] = LloydsAlgorithmCircumcenters(Px,Py, crs, numIterations)
            % LLOYDSALGORITHMCIRCUMCENTER runs Lloyd's algorithm on the particles at xy positions
            % (Px,Py) within the boundary polygon crs for numIterations iterations
            %
            % Note: R returns the n x 1 vector of radii of each particle's
            % minimum bounding circle
            %
            % Lloyd's algorithm (circumcenter) starts with an initial distribution of samples or
            % points and consists of repeatedly executing one relaxation step:
            %   1.  The Voronoi diagram of all the points is computed.
            %   2.  Each cell of the Voronoi diagram has its minimum bounding circle computed.
            %   3.  Each point is then moved to the center of its Voronoi cell's minimum bounding circle.
            %
            % Inspired by http://www.mathworks.com/matlabcentral/fileexchange/34428-voronoilimit
            % Requires the Polybool function of the mapping toolbox to run.
            %
            % Originally sourced from Aaron Becker: https://www.mathworks.com/matlabcentral/fileexchange/41507-lloydsalgorithm-px-py-crs-numiterations-showplot
            % Modified by Andrew McDonald for use in OpenSwarm
           
            % Iteratively Apply LLYOD's Algorithm
            for counter = 1:numIterations
                
                [vertices,cells]=Voronoi.VoronoiBounded(Px,Py, crs);
                
                for i = 1:numel(cells) %calculate the centroid of each cell
                    
                    % Construct an n x 2 matrix of voronoi polygon points
                    polygon = [vertices(cells{i},1),vertices(cells{i},2)];
                    
                    % Compute minimum bounding circle of polygon
                    [center, rad] = Voronoi.PolyBoundingCircle(polygon);
                    
                    % Get x, y coords of center point
                    Px(i) = center(1,1);
                    Py(i) = center(1,2);
                    
                    % Update radius return variable with this MBC's radius
                    R(i,1) = rad;
                end
            end
        end
        
        function [Px, Py, polygons] = LloydsAlgorithmCentroidsNumerically(Px,Py, crs, Tx, Ty, f)
            % LLOYDSALGORITHMCENTROID runs Lloyd's algorithm on the particles at xy positions
            % (Px,Py) within the boundary polygon crs for numIterations iterations
            %
            % Lloyd's algorithm (centroid) starts with an initial distribution of samples or
            % points and consists of repeatedly executing one relaxation step:
            %   1.  The Voronoi diagram of all the points is computed.
            %   2.  Each cell of the Voronoi diagram is integrated and the centroid is computed.
            %   3.  Each point is then moved to the centroid of its Voronoi cell.
            % 
            % PARAMS
            % Px: vector of starting x coordinates
            % Py: vector of starting y coordinates
            % crs: polygon in which to compute voronoi diagram
            % Tx: vector of test x coordinates at which f is sampled
            % Ty: vector of test y coordinates at which f is sampled
            % f:  vector of test function values at sampled X and Y coordinates
            %     specified by Tx and Ty
            %
            % RETURNS
            % Px: vector of centroid x coordinates
            % Py: vector of centroid y coordinates
            % polygons: vector of polygon objects of each voronoi cell
            %
            % Inspired by http://www.mathworks.com/matlabcentral/fileexchange/34428-voronoilimit
            % Requires the Polybool function of the mapping toolbox to run.
            %
            % Originally sourced from Aaron Becker: https://www.mathworks.com/matlabcentral/fileexchange/41507-lloydsalgorithm-px-py-crs-numiterations-showplot
            % Modified by Andrew McDonald for use in OpenSwarm with
            % nonuniform density functions
            
            % Construct voronoi diagram and initialize return vector
            [vertices,cells]=Voronoi.VoronoiBounded(Px,Py, crs);
            polygons = cell(size(Px, 1), 1);
            
            for i = 1:numel(cells) %calculate the centroid of each cell
                
                % Construct an n x 2 matrix of voronoi polygon points and
                % save into return vector
                polygon = [vertices(cells{i},1),vertices(cells{i},2)];
                polygons{i,1} = polygon;
                
                % Determine test points inside of this polygon
                in_indices = inpolygon(Tx, Ty, polygon(:,1), polygon(:,2));
                
                % Subset test points inside of this polygon
                in_tx = Tx(in_indices, 1);
                in_ty = Ty(in_indices, 1);
                in_f = f(in_indices, 1);
                
                % Compute numerical integral over region to obtain mass
                % by discrete approximation: compute the average value of
                % f, then multiply by the area of the region
                avg_f = mean(in_f);
                mass = avg_f * polyarea(polygon(:,1), polygon(:,2));
                
                % Compute numerical integral over region to obtain centers
                % by discrete approximation: compute the average value of
                % x*f, then multiply by the area of the region, then divide
                % by the mass of the region to get its center of mass
                avg_xf = mean(in_f .* [in_tx, in_ty]);
                weighted_mass = avg_xf * polyarea(polygon(:,1), polygon(:,2));
                centroid = weighted_mass / mass;
                Px(i) = centroid(1);
                Py(i) = centroid(2);

            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Polygonal Centroid %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [Cx,Cy] = PolyCentroid(X,Y)
            % POLYCENTROID returns the coordinates for the centroid of polygon with vertices X,Y
            % The centroid of a non-self-intersecting closed polygon defined by n vertices (x0,y0), (x1,y1), ..., (xn?1,yn?1) is the point (Cx, Cy), where
            % In these formulas, the vertices are assumed to be numbered in order of their occurrence along the polygon's perimeter, and the vertex ( xn, yn ) is assumed to be the same as ( x0, y0 ). Note that if the points are numbered in clockwise order the area A, computed as above, will have a negative sign; but the centroid coordinates will be correct even in this case.http://en.wikipedia.org/wiki/Centroid
            % A = polyarea(X,Y)
            %
            % Originally sourced from Aaron Becker: https://www.mathworks.com/matlabcentral/fileexchange/41507-lloydsalgorithm-px-py-crs-numiterations-showplot
            % Modified by Andrew McDonald for use in OpenSwarm
            
            Xa = [X(2:end);X(1)];
            Ya = [Y(2:end);Y(1)];
            
            A = 1/2*sum(X.*Ya-Xa.*Y); %signed area of the polygon
            
            Cx = (1/(6*A)*sum((X + Xa).*(X.*Ya-Xa.*Y)));
            Cy = (1/(6*A)*sum((Y + Ya).*(X.*Ya-Xa.*Y)));
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Voronoi Construction %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [V,C] = VoronoiBounded(x,y, crs)
            % VORONOIBOUNDED computes the Voronoi cells about the points (x,y) inside
            % the bounding box (a polygon) crs.  If crs is not supplied, an
            % axis-aligned box containing (x,y) is used.
            %
            % Originally sourced from Aaron Becker: https://www.mathworks.com/matlabcentral/fileexchange/41507-lloydsalgorithm-px-py-crs-numiterations-showplot
            % Modified by Andrew McDonald for use in OpenSwarm
            
            % V is the set of edge vertices
            
            bnd=[min(x) max(x) min(y) max(y)]; %data bounds
            if nargin < 3
                crs=double([bnd(1) bnd(4);bnd(2) bnd(4);bnd(2) bnd(3);bnd(1) bnd(3);bnd(1) bnd(4)]);
            end
            
            rgx = max(crs(:,1))-min(crs(:,1));
            rgy = max(crs(:,2))-min(crs(:,2));
            rg = max(rgx,rgy);
            midx = (max(crs(:,1))+min(crs(:,1)))/2;
            midy = (max(crs(:,2))+min(crs(:,2)))/2;
            
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
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Polygonal Min. Bounding Circle %%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [c, r] = PolyBoundingCircle(X)
            % POLYBOUNDINGCIRCLE: Wrapper function to simplify calls to
            % minCircle below
            n = size(X, 1);
            m = 1;
            bndry = [-5000, 5000; -5000, -5000; -5000, -5000];
            [c, r] = Voronoi.minCircle(n, X, m, bndry);            
        end
        
        function [C,minRad] = minCircle(n,p,m,b)
            %  MINCIRCLE    Finds the minimum circle enclosing a given set of 2-D points.
            %
            % Usage:
            %   [C,minRad] = minCircle(n,pts,m,bndry)
            %   where:
            %   OUTPUT:
            %    C: the center of the circle
            %    minRad: the radius of the circle
            %   INPUT:
            %    n: number of points given
            %    m: an argument used by the function. Always use 1 for m.
            %    bnry: an argument (3x2 array) used by the function to set the points that
            %          determines the circle boundry. You have to be careful when choosing this
            %          array's values. I think the values should be somewhere outside your points
            %          boundary. For my case, for example, I know the (x,y) I have will be something
            %          in between (-5,-5) and (5,5), so I use bnry as:
            %                       [-10 -10
            %                        -10 -10
            %                        -10 -10]
            % Notes:
            %  1. This function uses the "distance" and "findCenterRadius" functions.
            %  2. The n and b arguments are not actually inputs by the user. The should be
            %     set as described above. Since this function uses recursion, I couldn't
            %     omit them. If you can,do it!
            %
            %
            %
            %
            %   Rewritten from a Java applet by Shripad Thite (http://heyoka.cs.uiuc.edu/~thite/mincircle/).
            %
            %   Yazan Ahed (yash78@gmail.com)
            c = [-1 -1];
            r = 0;
            if (m == 2)
                c = b(1,:);
                r = 0;
            elseif (m == 3)
                c = (b(1,:) + b(2,:))/2;
                r = Voronoi.distance(b(1,:),c);
            elseif (m == 4)
                [C,minRad] = Voronoi.findCenterRadius(b(1,:),b(2,:),b(3,:));
                return;
            end
            C = c;
            minRad = r;
            for i = 1:n
                if(Voronoi.distance(p(i,:),C) > minRad)
                    if((b(1,:) ~= p(i,:)) & (b(2,:) ~= p(i,:)) & (b(3,:) ~= p(i,:)))
                        b(m,:) = p(i,:);
                        [C,minRad] = Voronoi.minCircle(i,p,m+1,b);
                    end
                end
            end
        end
        
        function d = distance(x,y)
            % DISTANCE   find the distance between two points in the Cartesian space
            %
            % Usage:
            %   distance = dist(x,y), where x and y are a 1x2 (2D) or 1x3 (3D) vectors.
            %
            d = sqrt(sum((x - y).^2));
        end
        
        function [C,Radius] = findCenterRadius(p1,p2,p3)
            % FINDCENTERRADIUS      finds the center and radius of a circle defined by three points.
            %
            % Usage:
            %   [C,Raduis] = findCenterRadius(p1,p2,p3), where:
            %       C: the circle's centre
            %       Raduis: the circle's radius
            %       p1, p2, p3: a two element vectors with the points (x,y) coordinates
            Xc = (p3(1)*p3(1) * (p1(2) - p2(2)) + (p1(1)*p1(1) + (p1(2) - p2(2))*(p1(2) - p3(2))) * (p2(2) - p3(2)) + p2(1)*p2(1) * (-p1(2) + p3(2))) / (2 * (p3(1) * (p1(2) - p2(2)) + p1(1) * (p2(2) - p3(2)) + p2(1) * (-p1(2) + p3(2))));
            Yc = (p2(2) + p3(2))/2 - (p3(1) - p2(1))/(p3(2) - p2(2)) * (Xc - (p2(1) + p3(1))/2);
            C = [Xc Yc];
            Radius = distance(C,p1);
        end
    end
end

