classdef HILGPC_Settings
    %HILGPC_SETTINGS Summary of this class goes here
    %   Object to carry global settings throughout the HILGPC project,
    %   including sample resolution, confidence thresholds, function
    %   types used in GP, etc.
    
    properties
        % Settings for use in evaluation of GP
        GridResolution
        ConfidenceThreshold
        
        % Functions for use in GP model
        MeanFunction
        CovFunction
        LikFunction        
    end
    
    methods
        function obj = HILGPC_Settings(resolution, threshold)
            %HILGPC_SETTINGS
            %   Instantiate settings object
            obj.GridResolution = resolution;
            obj.ConfidenceThreshold = threshold;
            
            % manually configure the following properties in this class
            % (they will not change often)
            obj.MeanFunction = @meanConst;
            obj.CovFunction = @covSEiso;
            obj.LikFunction = @likGaussian;
        end
    end
end

