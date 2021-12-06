function [outputArg1,outputArg2] = HeatmapMaker_trainPrediction(menu,eventdata,scene)
%HEATMAPMAKER_TRAINPREDICTION Summary of this function goes here
%   Detailed explanation goes here



%load training data
TrainingStack = VoxelDataStack();
TrainingStack.loadStudyDataFromRecipe();


% Train the model
PredModel = PredictionModel();
PredModel.SamplingMethod = SamplingMethod.choosedlg();
PredModel.trainOnVoxelDataStack(TrainingStack)
PredModel.plotTraining;
PredModel.save()







keyboard

end

