classdef HILGPC_Settings
    %HILGPC_SETTINGS Summary of this class goes here
    %   Object to carry global settings throughout the HILGPC project,
    %   including sample resolution, confidence thresholds, function
    %   types used in GP, etc.
    
    properties
        % Reuse saved user input?
        RecycleLofiPrior
        LofiFilename
        
        % Save sampled data?
        RecycleHifiPrior
        HifiFilename
        
        GroundTruthFilename
        
        % Settings for use in evaluation of GP
        GridResolution
        S2Threshold
        MaxEvals          % function evaluation limit for minimize
        MaxClicks         % levels of user input
        DistanceThreshold % between user input points
        EdgeGuard         % how close to the screen edges robots may get
        
        % Functions for use in GP model
        MeanFunction
        CovFunction
        LikFunction        
    end
    
    methods
        function obj = HILGPC_Settings(threshold, recycle_lofi, lofi_filename, recycle_hifi, hifi_filename)
            %HILGPC_SETTINGS
            %   Instantiate settings object
            obj.S2Threshold = threshold;
            obj.RecycleLofiPrior = recycle_lofi;
            obj.LofiFilename = lofi_filename;
            obj.RecycleHifiPrior = recycle_hifi;
            obj.HifiFilename = hifi_filename;
            
            % manually configure the following properties in this class
            % (they will not change often)
            obj.GridResolution = 10;
            obj.DistanceThreshold = 50;
            obj.EdgeGuard = 50;
            obj.MaxEvals = 10;
            obj.MaxClicks = 5;
            obj.MeanFunction = [];
            obj.CovFunction = @covSEiso;
            obj.LikFunction = @likGauss;
            
            obj.GroundTruthFilename = '../Data/lofi_train_dense.csv';
        end
    end
end

