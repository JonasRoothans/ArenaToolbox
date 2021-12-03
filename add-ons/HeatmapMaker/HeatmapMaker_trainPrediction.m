function [outputArg1,outputArg2] = HeatmapMaker_trainPrediction(menu,eventdata,scene)
%HEATMAPMAKER_TRAINPREDICTION Summary of this function goes here
%   Detailed explanation goes here


% waitfor(msgbox({'This is how we proceed:','1. First you select a recipe, this can be a new or legacy recipe',...
%     '2. Then you select a template space as a canvas',...
%     'In a leave one out fashion heatmaps are created and sampled',...
%     '3. Finally you choose which algorithm you want to use for prediction',...
%     'This algorithm will be saved.'},'Arena trainer','help'))




%load training data
TrainingStack = VoxelDataStack();
TrainingStack.loadStudyDataFromRecipe();


%ask for title and description



PredModel = PredictionModel();
PredModel.SamplingMethod = SamplingMethod.choosedlg();
PredModel.trainOnVoxelDataStack(TrainingStack)
PredModel.plotTraining;
PredModel.save()







keyboard

end

