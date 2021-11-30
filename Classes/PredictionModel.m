classdef PredictionModel < handle
    %PREDICTIONMODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Heatmap
        SamplingMethod = @A_15bins;
        %Tag
        %Description
    end
    
    properties (Hidden)
        TrainingLinearModel
        B
    end
    
    methods
        function obj = PredictionModel(inputArg1,inputArg2)
        end
        
        function bool = isTrained(obj)
            bool = ~isempty(obj.B);
        end
        
        function obj = trainOnVoxelDataStack(obj,VDS,SamplingMethod)
            %user rinput
            UserInput = inputdlg({'HeatmapName','Description'},...
                          'Heatmap maker', [1 50; 3 50],...
                          {VDS.ScoreLabel,''}); 
            FILENAME = UserInput{1};
            DESCRIPTION = UserInput{2};

            %XXX REMOVED: LOO heatmaps will be made on the fly.    
            %make heatmaps
            %LOOmaps = VDS.convertToLOOHeatmaps;
            %obj.Heatmap = VDS.convertToHeatmap(FILENAME,DESCRIPTION);
            
            %Run a regression
            TrainingModule = LOORoutine();
            TrainingModule.SamplingMethod = obj.SamplingMethod; %pass on
            TrainingModule.VDS = VDS;
            TrainingModule.LOOregression();
            
            obj.TrainingLinearModel = TrainingModule.LOOmdl;
            obj.B = TrainingModule.LOOmdl.Coefficients.Estimate;
            
            obj.printTrainingDetails
            
        end
        
        function printTrainingDetails(obj)
            obj.TrainingLinearModel
        end
        
        function plotTraining(obj)
            figure;
            if isempty(obj.TrainingLinearModel);return;end
            scatter(obj.TrainingLinearModel.Variables.y,...
                obj.TrainingLinearModel.predict);
            hold on;
            line(xlim,xlim,'Color','red','LineStyle','--')
            xlabel(obj.Heatmap.Tag)
            ylabel('Model prediction')
            title({'LOO training model',['R^2:', num2str(obj.TrainingLinearModel.Rsquared.Ordinary)]})
        end
        
        function [prediction,predictors] = predictVoxelData(obj,VD, SimilarityMethod)
           
            ba = BiteAnalysis(obj.Heatmap.Signedpmap,VD,SimilarityMethod, obj.Heatmap.Tmap); 
            predictors = ba.SimilarityResult;
            
            %apply B
            try
            prediction = [1,predictors]*obj.B;
            catch
                error('please train model before applying prediction');
            end
        end
        
        function mdl = validateOnVoxelDataStack(obj,VDS)
            n = length(VDS);
            predictorslist = {};
            predictions = [];
            for i= 1:n
                [prediction,predictors] = predictVoxelData(obj,VDS.getVoxelDataAtPosition(i));
                predictorslist{i} = predictors;
                predictions(i) = prediction;
            end
            
            mdl= fitlm(VDS.Weights,predictions);
            
        end
        
        function save(obj)
            global arena
            root = arena.getrootdir;
            modelFolder = fullfile(root,'Elements','PredictionModels');
            if ~exist(modelFolder,'dir')
                mkdir(modelFolder)
            end
            mdl = obj;
            formatOut = 'yyyy_mm_dd';
            disp(['saving as: ',datestr(now,formatOut),'_',obj.Heatmap.Tag])
            save(fullfile(modelFolder,[datestr(now,formatOut),'_',obj.Heatmap.Tag]),'mdl','-v7.3')
            disp('Saving complete')
        end
        
        
        function obj = load(obj)
            global arena
            root = arena.getrootdir;
            modelFolder = fullfile(root,'Elements','PredictionModels');
            if ~exist(modelFolder,'dir')
                error('../Elements/PredictionModels does not exist!')
            end
            mdlpath = uigetfile(fullfile(modelFolder,'*.mat'));
            disp('Loading...')
            loaded = load(fullfile(modelFolder,mdlpath));
          
            
            obj.Heatmap = loaded.mdl.Heatmap;
            obj.SamplingMethod = loaded.mdl.SamplingMethod;
            obj.TrainingLinearModel = loaded.mdl.TrainingLinearModel;
            obj.B = loaded.mdl.B;
        end
    end
end

