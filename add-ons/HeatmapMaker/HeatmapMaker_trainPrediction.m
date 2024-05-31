function [outputArg1,outputArg2] = HeatmapMaker_trainPrediction(menu,eventdata,scene)
%HEATMAPMAKER_TRAINPREDICTION Summary of this function goes here
%   Detailed explanation goes here



%load training data
TrainingStack = VoxelDataStack();
TrainingStack.loadStudyDataFromRecipe();
TrainingStack.doYouWantSmoothing()


% Train the model
PredModel = PredictionModel();
PredModel.SamplingMethod = SamplingMethod.choosedlg();
PredModel.trainOnVoxelDataStack(TrainingStack)
PredModel.plotTraining;
PredModel.save()
    

answer = questdlg('Do you want to quickly simulate a prediction (LOOCV)','wait.. there is more!','Yes, the results are good enough to try','don''t bother','Yes, the results are good enough to try');
switch answer
    case 'Yes, the results are good enough to try'
        PredModel.LOOCV
end




keyboard

end

