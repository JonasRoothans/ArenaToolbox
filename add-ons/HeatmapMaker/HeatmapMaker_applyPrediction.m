function [outputArg1,outputArg2] = HeatmapMaker_applyPrediction(menu,eventdata,scene)
%HEATMAPMAKER_TRAINPREDICTION Summary of this function goes here
%   Detailed explanation goes here





%ask for title and description
PredModel = PredictionModel();
PredModel.load();


%load training data
ValidationStack = VoxelDataStack();
ValidationStack.templateSpace(PredModel.Heatmap)
ValidationStack.loadStudyDataFromRecipe();


mdl = PredModel.validateOnVoxelDataStack(ValidationStack)
assignin('base','mdl',mdl)
disp('Model has been saved to workspace as ''mdl''')

%%

end

