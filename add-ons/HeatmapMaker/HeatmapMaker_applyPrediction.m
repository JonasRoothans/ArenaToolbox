function [outputArg1,outputArg2] = HeatmapMaker_applyPrediction(menu,eventdata,scene)
%HEATMAPMAKER_TRAINPREDICTION Summary of this function goes here
%   Detailed explanation goes here


waitfor(msgbox({'This is how we proceed:','1. First you select a recipe, this can be a new or legacy recipe',...
    '2. Then you select a template space as a canvas',...
    'In a leave one out fashion heatmaps are created and sampled',...
    '3. Finally you choose which algorithm you want to use for prediction',...
    'This algorithm will be saved.'},'Arena trainer','help'))




%load training data
ValidationStack = VoxelDataStack();
ValidationStack.loadStudyDataFromRecipe();


%ask for title and description
PredModel = PredictionModel();
PredModel.load();


%%%
          
% %prepare taining maps          
% LOOmaps = TrainingStack.convertToLOOHeatmaps(FILENAME,DESCRIPTION);
% Heatmap = TrainingStack.convertToHeatmap(FILENAME,DESCRIPTION);
% Heatmap.save(fullfile(fileparts(TrainingStack.RecipePath),FILENAME))
% 
% %run training
% TrainingModule = LOORoutine();
% TrainingModule.Heatmap = LOOmaps;
% TrainingModule.Memory = TrainingStack;
% TrainingModule.LOOregression();
% TrainingModule.saveTraining(fileparts(TrainingStack.RecipePath))






keyboard

end

