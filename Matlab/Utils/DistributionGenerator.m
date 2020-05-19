classdef DistributionGenerator
    %DISTRIBUTIONGENERATOR Used to generate distributions for testing
    
    properties
        % Vector of all graphics handles generated
        Handles = []
    end
    
    methods
        
        function obj = DistributionGenerator
            
        end
        
        function [truth, lofi, hifi] = may_18_generator(obj, hilgpc_data)
            
            close all;
            
            % Configure possible distributions
            % zig_zag = [100,100; 300,200; 400,100; 600,200];
            corners = [0.2,0.2; 0.8,0.2; 0.8,0.8; 0.2,0.8];
            %sides = [0.2,0.2; 0.2,0.4; 0.2,0.6; 0.2,0.8];
            
            % Configure random distribution
            rng(1);
            num = 10;
            random = zeros(num,2);
            for i = 1:num
                random(i, 1) = rand * hilgpc_data.Environment.XAxisSize;
                random(i, 2) = rand * hilgpc_data.Environment.YAxisSize;
            end
            
            % Pick distribution and construct ground-truth
            centers = corners;
            len = 0.05;
            s2 = 1;
            truth = obj.SquaredExponential(hilgpc_data, centers, len, s2);
                      
            % Construct hifi from truth
            proportion = 1;
            len = 0.05;
            hifi = obj.ConstructHifi(hilgpc_data, truth, proportion, len);
            
            % Construct bias as lofi
            proportion = 1;
            len = 0.2;
            lofi = 0.5 .* obj.ConstructSmooth(hilgpc_data, truth, proportion, len);
            
            % Construct hifi = a*lofi + bias
            %autocorrelation = 1;
            %lofi = obj.ConstructLofi(hilgpc_data, hifi, bias, autocorrelation);
            
            % Compose all figures into subplot
            figHandles = findall(groot, 'Type', 'figure');
            figHandles = flip(figHandles);
            obj.Figs2Subplots(figHandles);
            colormap(jet);
        end
        
        function [truth, lofi, bias, hifi] = may_8_generator(obj, hilgpc_data)
            
            close all;
            
            % Configure possible distributions
            zig_zag = [100,100; 300,200; 400,100; 600,200];
            corners = [100,100; 100,200; 600,100; 600,200];
            rng(300);
            num = 10;
            random = zeros(num,2);
            for i = 1:num
                random(i, 1) = rand * hilgpc_data.Environment.XAxisSize;
                random(i, 2) = rand * hilgpc_data.Environment.YAxisSize;
            end
            
            % Pick distribution and construct ground-truth
            centers = random;
            len = 50;
            s2 = 1;
            truth = obj.SquaredExponential(hilgpc_data, centers, len, s2);
                      
            % Construct lofi
            proportion = 1;
            len = 100;
            lofi = obj.ConstructLofi(hilgpc_data, truth, proportion, len);
            
            % Construct bias
            proportion = 1;
            len = 20;
            bias = obj.ConstructBias(hilgpc_data, truth, proportion, len);
            
            % Construct hifi = a*lofi + bias
            autocorrelation = 1;
            hifi = obj.ConstructHifi(hilgpc_data, lofi, bias, autocorrelation);
            
            % Compose all figures into subplot
            figHandles = findall(groot, 'Type', 'figure');
            figHandles = flip(figHandles);
            obj.Figs2Subplots(figHandles);
            colormap(jet);
        end
        
        function z = SquaredExponential(obj, hilgpc_data, centers, len, s2)
            % Generate a squared exponential four-corner function over x
            %
            % hilgpc_data : HILGPC_Data object with meshgrid points
            
            x = hilgpc_data.TestPoints;
            
            % centers = [100,100; 300,200; 400,100; 600,200];
            % len = 50;
            % s2 = 5;
            z = zeros(size(x,1), 1);
            
            for i = 1:size(centers,1)
                
                % add squared kerned based at each center point
                center = centers(i,:);
                
                deltaX2 = (x(:,1) - center(:,1)).^2 + (x(:,2) - center(:,2)).^2;
                power = -deltaX2 ./ (2 * len * len);
                term = s2 .* exp(power);
                z = z + term;
                
            end
            
            z = obj.Normalize(z);
            
            % Compute numerical integral of function
            mean_z = mean(z);
            dx = max(hilgpc_data.TestPoints(:,1)) - min(hilgpc_data.TestPoints(:,1));
            dy = max(hilgpc_data.TestPoints(:,2)) - min(hilgpc_data.TestPoints(:,2));
            area = dx * dy;
            
            
            integral_ground_truth = area * mean_z;
            disp('Ground Truth Integral:');
            disp(integral_ground_truth);
            
            obj.Visualize(hilgpc_data, z);
            title('Ground Truth Function');
            
        end
        
        function Visualize(obj, hilgpc_data, z)
            % Visualize generated function with heatmap
            %
            % hilgpc_data : HILGPC_Data object with meshgrid points
            % z : function values generated by generated function
            
            figure;
            meshX = hilgpc_data.TestMeshX;
            meshY = hilgpc_data.TestMeshY;
            mesh(meshX, meshY, reshape(z, size(meshX, 1), []), 'FaceColor', 'interp', 'EdgeColor', 'None');
            colormap('jet');
            view(2);
            daspect([1,1,1]);
                        
        end
        
        function ScatterSamples(obj, samples)
            % Scatter sampled points used for kernel function
            %
            % samples : n x 3 array of [x, y, z] pairs to scatter
            
            figure;
            scatter(samples(:,1), samples(:,2), 30, samples(:,3), 'filled');
            daspect([1,1,1]);
            colormap(jet);
        end
        
        function SaveDistributionGrid(obj, filename, hilgpc_data, z, proportion, offset)
            % Save distribution for training or testing
            % Can be used to save ground truth function as baseline,
            % or to save lofi/hifi for testing purposes
            % Select proportion of points in gridded manner
            %
            % filename : where to save ground truth to
            % hilgpc_data : HILGPC_Data object with meshgrid points
            % z : function values generated by generated function
            % proportion : proportion of points to save
            % offset : number of gridded rows to offset on sample - use
            %     this to ensure duplicate points are not taken, as these
            %     will crash the training algorithm
            
            distribution = cat(2, hilgpc_data.TestPoints, z);
            distribution(1, 4) = 1;
            
            % take proportion * n gridded samples for save set
            flag = round(1 / proportion);
            save_idx = [];

            for row = offset:flag:size(hilgpc_data.TestMeshX, 1)
                for col = offset:flag:size(hilgpc_data.TestMeshX, 2)
                    x = hilgpc_data.TestMeshX(row, col);
                    y = hilgpc_data.TestMeshY(row, col);
                    point_idx = find(x==distribution(:,1) & y==distribution(:,2));
                    save_idx(size(save_idx,1) + 1, 1) = point_idx;
                end
            end
            
            save_points = distribution(save_idx, :);
            
            if proportion == 1
                save_points = distribution;
            end
            
            % Scatter kernel points
            obj.ScatterSamples(save_points);
            title(sprintf('Save Points: %s', filename));
            
            file = fopen(filename, 'w');
            fprintf(file, "X,Y,Means,Confidence\n");
            fclose(file);
            
            dlmwrite(filename, save_points, '-append');
            
        end
        
        function SaveDistributionRandom(obj, filename, hilgpc_data, z, proportion, seed)
            % Save distribution for training or testing
            % Can be used to save ground truth function as baseline,
            % or to save lofi/hifi for testing purposes
            % Select proportion of points in random manner
            %
            % filename : where to save ground truth to
            % hilgpc_data : HILGPC_Data object with meshgrid points
            % z : function values generated by generated function
            % proportion : proportion of points to save
            % seed : random seed to use when generating number
            
            distribution = cat(2, hilgpc_data.TestPoints, z);
            distribution(1, 4) = 1;
            
            rng(seed);
            
            % take proportion * n gridded samples for save set
            save_idx = randsample(1:size(distribution,1), round(proportion * size(distribution, 1)))';
            save_points = distribution(save_idx, :);
            
            % Scatter kernel points
            obj.ScatterSamples(save_points);
            title(sprintf('Save Points: %s', filename));
            
            file = fopen(filename, 'w');
            fprintf(file, "X,Y,Means,Confidence\n");
            fclose(file);
            
            dlmwrite(filename, save_points, '-append');
            
        end
        
        function OldSaveHifi(obj, filename, hilgpc_data, z, proportion)
            % Save high fidelity grid for use in training hyperparams
            %
            % filename : where to save hifi to
            % hilgpc_data : HILGPC_Data object with meshgrid points
            % z : function values generated by generated function
            
            dist = cat(2, hilgpc_data.TestPoints, z);
            
            % take proportion * n random samples for lofi set
            sample_idx = randsample(1:size(dist,1), round(proportion * size(dist, 1)))';
            hifi = dist(sample_idx, :);
            
            % preview what's being saved
            figure;
            scatter(hifi(:,1), hifi(:,2), 50, hifi(:,3), 'filled')
            title('Hifi - No Noise');
            colorbar;
                        
            % save
            file = fopen(filename, 'w');
            fprintf(file, "X,Y,Means\n");
            fclose(file);
            
            dlmwrite(filename, hifi, '-append');
            
        end
        
        function OldSaveLofi(obj, filename, hilgpc_data, z, proportion, sn)
            % Save low fidelity grid for use in training hyperparams
            %
            % Take a random subset of high fidelity training points, add
            % Gaussian noise, and save for training
            %
            % filename : where to save lofi to
            % hilgpc_data : HILGPC_Data object with meshgrid points
            % z : function values generated by generated function
            % proportion : proportion of hifi points to keep in lofi
            % sn : sample noise to add to lofi points
            
            dist = cat(2, hilgpc_data.TestPoints, z);
            
            % take proportion * n random samples for lofi set
            sample_idx = randsample(1:size(dist,1), round(proportion * size(dist, 1)))';
            samples = dist(sample_idx, :);
            
            % add gaussian noise to lofi set
            noise = normrnd(0, sn, size(samples, 1), 1);            
            lofi = [samples(:, 1:2), samples(:, 3) + noise];
            
            % preview what's being saved
            figure;
            scatter(samples(:,1), samples(:,2), 50, samples(:,3), 'filled')
            title('Lofi - No Noise');
            colorbar;
            figure;
            scatter(lofi(:,1), lofi(:,2), 50, lofi(:,3), 'filled')
            title('Lofi - Noise Added');
            colorbar;
                        
            % save
            file = fopen(filename, 'w');
            fprintf(file, "X,Y,Means\n");
            fclose(file);
            
            dlmwrite(filename, lofi, '-append');
            
        end
        
        function hifi = ConstructHifi(obj, hilgpc_data, z, proportion, len)
            % Construct high fidelity model given ground truth
            %
            % (1) Take downsized sample of ground truth points according to
            % specified proportion
            % (2) Predict rest of ground truth points using specified
            % lengthscale
            % (3) Return grid of hifi-predicted points
            %
            % hilgpc_data : HILGPC_Data object with meshgrid points
            % z : ground truth points used to generate lofi representation
            % proportion : proportion of ground truth points used to
            %    construct kernel base points along one-dimension - note
            %    that this will yield only proportion^2 points
            % len : lengthscale to be used in lofi prediction base points
                      
            distribution = cat(2, hilgpc_data.TestPoints, z);
            
            % take proportion * n gridded samples for kernel set
            flag = round(1 / proportion);
            kernel_idx = [];

            for row = 1:flag:size(hilgpc_data.TestMeshX, 1)
                for col = 1:flag:size(hilgpc_data.TestMeshX, 2)
                    x = hilgpc_data.TestMeshX(row, col);
                    y = hilgpc_data.TestMeshY(row, col);
                    point_idx = find(x==distribution(:,1) & y==distribution(:,2));
                    kernel_idx(size(kernel_idx,1) + 1, 1) = point_idx;
                end
            end
            
            kernel_points = distribution(kernel_idx, :);
            
            % Scatter kernel points
            obj.ScatterSamples(kernel_points);
            title('Hifi Sample Points');
            
            hifi = zeros(size(distribution,1), 1);
            
            for i = 1:size(kernel_points,1)
                
                % add squared kerned based at each center point
                center = kernel_points(i,1:2);
                var = kernel_points(i,3);
                
                deltaX2 = (distribution(:,1) - center(:,1)).^2 + (distribution(:,2) - center(:,2)).^2;
                power = -deltaX2 ./ (2 * len * len);
                term = var .* exp(power);
                hifi = hifi + term;
                
            end
            
            hifi = obj.Normalize(hifi);
            
            % Compute numerical integral of function
            mean_z = mean(hifi);
            dx = max(hilgpc_data.TestPoints(:,1)) - min(hilgpc_data.TestPoints(:,1));
            dy = max(hilgpc_data.TestPoints(:,2)) - min(hilgpc_data.TestPoints(:,2));
            area = dx * dy;
            
            
            integral_hifi = area * mean_z;
            disp('Hifi Integral:');
            disp(integral_hifi);
                      
            obj.Visualize(hilgpc_data, hifi);
            title('Hifi Function');

            
        end
        
        function smooth = ConstructSmooth(obj, hilgpc_data, z, proportion, len)
            % Construct bias process given ground truth following
            % model specified by Lai Wei
            %
            % (1) Take downsized sample of truth points according to
            % specified proportion
            % (2) Predict rest of ground truth points using specified
            % lengthscale (should be shorter than lofi) using additive
            % model
            % (3) Return grid of bias-predicted points
            %
            % hilgpc_data : HILGPC_Data object with meshgrid points
            % z : truth points used to generate bias representation
            % proportion : proportion of truth points used to
            %    construct kernel base points along one-dimension - note
            %    that this will yield only proportion^2 points
            % len : lengthscale to be used in bias prediction base points
            
            rng(100);
            
            distribution = cat(2, hilgpc_data.TestPoints, z);
            
            % take proportion * n gridded samples for kernel set
            flag = round(1 / proportion);
            kernel_idx = [];

            for row = 1:flag:size(hilgpc_data.TestMeshX, 1)
                for col = 1:flag:size(hilgpc_data.TestMeshX, 2)
                    x = hilgpc_data.TestMeshX(row, col);
                    y = hilgpc_data.TestMeshY(row, col);
                    point_idx = find(x==distribution(:,1) & y==distribution(:,2));
                    kernel_idx(size(kernel_idx,1) + 1, 1) = point_idx;
                end
            end
            
            % pull kernel points of hifi representation from lofi set
            kernel_points = distribution(kernel_idx, :);
            
            % Scatter kernel points
            obj.ScatterSamples(kernel_points);
            title('Smooth Sample Points');
            
            smooth = zeros(size(distribution,1), 1);
            
            for i = 1:size(kernel_points,1)
                
                % add squared kerned based at each center point
                center = kernel_points(i,1:2);
                var = kernel_points(i,3);
                
                deltaX2 = (distribution(:,1) - center(:,1)).^2 + (distribution(:,2) - center(:,2)).^2;
                power = -deltaX2 ./ (2 * len * len);
                term = var .* exp(power);
                smooth = smooth + term;
                
            end
            
            smooth = obj.Normalize(smooth);
            
            % Compute numerical integral of function
            mean_z = mean(smooth);
            dx = max(hilgpc_data.TestPoints(:,1)) - min(hilgpc_data.TestPoints(:,1));
            dy = max(hilgpc_data.TestPoints(:,2)) - min(hilgpc_data.TestPoints(:,2));
            area = dx * dy;
            
            
            integral_smooth = area * mean_z;
            disp('Smooth Integral:');
            disp(integral_smooth);
                      
            obj.Visualize(hilgpc_data, smooth);
            title('Smooth Function');
            
        end
        
        function lofi = ConstructLofi(obj, hilgpc_data, hifi, bias, a)
           % Construct lofi process given hifi and bias process
           % according to model specified by Lai Wei
           %
           % hifi : g_1 points of hifi process
           % bias : b_1 points of bias between levels
           % a : autocorrelation between levels
           
           % Compute lofi from hifi and bias
           lofi = (1/a) .* hifi - bias;  
           lofi = obj.Normalize(lofi);
           
           % Compute numerical integral of lofi
           mean_z = mean(lofi);
           dx = max(hilgpc_data.TestPoints(:,1)) - min(hilgpc_data.TestPoints(:,1));
           dy = max(hilgpc_data.TestPoints(:,2)) - min(hilgpc_data.TestPoints(:,2));
           area = dx * dy;
                      
           integral_lofi = area * mean_z;
           disp('Lofi Integral:');
           disp(integral_lofi);
           
           % Visualize hifi
           obj.Visualize(hilgpc_data, lofi);
           title('Lofi Function');
            
        end
        
        function z = Normalize(obj, z)
            z = z - min(z);
            z = z ./ max(z);
        end
        
        function newfig = Figs2Subplots(obj, handles, tiling, arr)
            % FIGS2SUBLPLOTS Combine axes in many figures into subplots in one figure
            %
            %   The syntax:
            %
            %       >> newfig = figs2subplots(handles,tiling,arr);
            %
            %   creates a new figure with handle "newfig", in which the axes specified
            %   in vector "handles" are reproduced and aggregated as subplots.
            %
            %   Vector "handles" is a vector of figure and/or axes handles. If an axes
            %   handle is encountered, the corresponding axes is simply reproduced as
            %   a subplot in the new figure; if a figure handle is encountered, all its
            %   children axes are reproduced as subplots in the figure.
            %
            %   Vector "tiling" is an optional subplot tiling vector of the form
            %   [M N], where M and N specify the number of rows and columns for the
            %   subplot tiling. M and N correspond to the first two arguments of the
            %   SUBPLOT command. By default, the tiling is such that all subplots are
            %   stacked in a column.
            %
            %   Cell array "arr" is an optional subplot arrangement cell array. For
            %   the k-th axes handle encountered, the subplot command issued is
            %   actually:
            %
            %       subplot(tiling(1),tiling(2),arr{k})
            %
            %   By default, "arr" is a cell array {1,2,...}, which means that each axes
            %   found in the figures is reproduced in a neatly tiled grid.
            %
            %   Example:
            %
            %       figs2subplots([a1 a2 a3],[2 2],{[1 3],2,4})
            %
            %   copies the three axes a1, a2 and a3 as subplots in a new figure with a
            %   2x2 tiling arangement. Axes a1 will be reproduced as a subplot
            %   occupying tiles 1 and 3 (thus covering the left part of the figure),
            %   while axes a2 will be reproduced as a subplot occupying tile 2 (upper
            %   right corner) and a3 occupying tile 4 (lower right corner).
            %   Original version by François Bouffard (fbouffard@gmail.com)
            %   Legend copy code by Zoran Pasaric (pasaric@rudjer.irb.hr)
            %
            % From MATLAB file exchange: https://www.mathworks.com/matlabcentral/fileexchange/6459-figs2subplots
            
            % Parsing handles vector
            av = [];
            for k = 1:length(handles)
                if strcmp(get(handles(k),'Type'),'axes')
                    av = [av handles(k)];
                elseif strcmp(get(handles(k),'Type'),'figure');
                    fc = get(handles(k),'Children');
                    for j = length(fc):-1:1
                        if strcmp(get(fc(j),'Type'),'axes') && ~strcmp(get(fc(j),'Tag'),'legend')
                            av = [av fc(j)];
                        end;
                    end;
                end;
            end;
            % --- find all legends
            hAxes = findobj('type','axes');
            tags = get(hAxes,'tag');
            iLeg = strmatch('legend',tags);
            hLeg = hAxes(iLeg); % only legend axes
            userDat = get(hLeg,'UserData');
            % Extract axes handles that own particular legend, and corresponding strings
            hLegParAxes = [];
            hLegString = {};
            for i1 = 1:length(userDat)
                hLegParAxes(i1) = userDat{i1}.PlotHandle;
                hLegString{i1} = userDat{i1}.lstrings;
            end
            % Setting the subplots arrangement
            Na = length(av);
            if nargin < 3
                tiling = [Na 1];
                Ns = Na;
            else
                Ns = prod(tiling);
            end;
            if nargin < 4
                arr = mat2cell((1:Ns)',ones(1,Ns));
            end;
            if ~iscell(arr)
                error('Arrangement must be a cell array');
            end;
            % Creating new figure
            da = zeros(1,Ns);
            newfig = figure;
            for k = 1:min(Ns,Na)
                da(k) = subplot(tiling(1),tiling(2),arr{k});
                na = copyobj(av(k),newfig);
                set(na,'Position',get(da(k),'Position'));
%                 zlim(na, [0,2]);
%                 view(na, 90,0);
%                 daspect(na, [100,100,1]);
                % Produce legend if it exists in original axes
                [ii jj] = ismember(av(k),hLegParAxes);
                if(jj>0)
                    axes(na);
                    legend(hLegString{jj});
                end
                delete(da(k));
            end
        end
    end
end

