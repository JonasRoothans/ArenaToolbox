classdef PredictionModel < handle
    %PREDICTIONMODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Heatmap
        SamplingMethod = @A_15bins;
        Tag
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
        
        function obj = trainOnVoxelDataStack(obj,VDS,customMethod)
            if nargin==3
                obj.SamplingMethod = customMethod;
            end
            
            %get required info from the SamplingMethod
            samplingMethod = feval(obj.SamplingMethod);
            requiredMaps = samplingMethod.RequiredHeatmaps;
            
            %Make a Heatmap including all data.
            disp('Making a heatmap based on all data')
            heatmap=Heatmap(); %#ok<CPROPLC>
            try
                [~,foldername] = fileparts(fileparts(VDS.RecipePath));
                propertyname = VDS.ScoreLabel;
                nameSuggestion = [foldername,' ',propertyname];
                description = [];
            catch
                disp('name suggestion failed..')
                nameSuggestionn = [];
                description = [];
            end
                
            heatmap.fromVoxelDataStack(VDS,nameSuggestion,description,requiredMaps);
            obj.Heatmap = heatmap;
           
            
            %Run a Leave one out training routine
            TrainingModule = LOORoutine();
            TrainingModule.SamplingMethod = obj.SamplingMethod; %pass on
            TrainingModule.VDS = VDS;
            TrainingModule.LOOregression();
            
            obj.TrainingLinearModel = TrainingModule.LOOmdl;
            obj.B = TrainingModule.LOOmdl.Coefficients.Estimate;
            obj.Tag = obj.Heatmap.Tag;
            
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
        
        function [prediction,predictors] = predictVoxelData(obj,VD)
           
           
            ba = BiteAnalysis(obj.Heatmap,VD,obj.SamplingMethod);
            predictors = ba.Predictors;
            
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
            modelFolder = fullfile(root,'UserData','PredictionModels');
            if ~exist(modelFolder,'dir')
                mkdir(modelFolder)
            end
            mdl = obj;
            formatOut = 'yyyy_mm_dd';
            disp(['saving as: ',datestr(now,formatOut),'_',obj.Heatmap.Tag,'_',func2str(obj.SamplingMethod),' in ../ArenaToolbox/UserData/PredictionModels'])
            save(fullfile(modelFolder,[datestr(now,formatOut),'_',obj.Heatmap.Tag,'_',func2str(obj.SamplingMethod)]),'mdl','-v7.3')
            disp('Saving complete')
        end
        
        
        function obj = load(obj)
            global arena
            root = arena.getrootdir;
            modelFolder = fullfile(root,'UserData','PredictionModels');
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
            obj.Tag = loaded.mdl.Tag;
        end
        
        function LOOCV(obj)
            
            if ~isempty(obj.TrainingLinearModel)
                tbl  = obj.TrainingLinearModel.Variables;
                mtrx = table2array(tbl);
                predictors = mtrx(:,1:end-1);
                truth = mtrx(:,end);
                mdl = LOORoutine.quickLOOCV(predictors,truth')
            end
            
        end
    end
end

