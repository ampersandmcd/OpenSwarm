classdef HILGPC_Data
    %HILGPC_DATA
    %   Object to serve as a data payload throughout the HILGPC project,
    %   carrying human-input data, machine-sampled data, combined data
    %   used to train GP model, test data to predict with GP model, and
    %   hyperparameters of the GP model
    
    properties
        % Dependencies
        Environment     % OpenSwarm environment object
        
        % Human-input data
        InputPoints     % n rows by 2 col of human-input (x,y) points
        InputMeans      % n rows by 1 col of human-input means
        InputS2         % n rows by 1 col of human-input variances
        
        % Machine-sampled data
        SamplePoints    % n rows by 2 col of machine-sampled (x,y) points
        SampleMeans     % n rows by 1 col of machine-sampled means
        SampleS2        % n rows by 1 col of machine-sampled variances
        
        % Human-Machine combined data
        TrainPoints     % concatenation of InputPoints and SamplePoints
        TrainMeans      % concatenation of InputMeans and SampleMeans
        TrainS2         % concatenation of InputS2 and SampleS2
        
        % Predicted data (used to visualize the GP)
        TestPoints      % n rows by 2 col of (x,y) points to evaluate model
        TestMeans       % n rows output by model
        TestS2          % n rows output by model
        
        % Other relevant GP data
        Hyp             % hyperparameters of GP model
    end
    
    methods
        function obj = HILGPC_Data(environment, hilgpc_settings)
            % HILGPC_DATA
            %    Set environment dependency and generate test points
            
            obj.Environment = environment;
            
            [testX, testY] = meshgrid(0:hilgpc_settings.GridResolution:environment.XAxisSize, ...
                                        0:hilgpc_settings.GridResolution:environment.YAxisSize);
            obj.TestPoints = reshape([testX, testY], [], 2);
        end
    end
end

