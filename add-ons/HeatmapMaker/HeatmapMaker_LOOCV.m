function [outputArg1,outputArg2] = HeatmapMaker_LOOCV(menu,eventdata,scene)
%SWEETSPOTSTATION_MAKERECIPE Summary of this function goes here
%   Detailed explanation goes here


 waitfor(msgbox('This works if you have already trained a prediction model. Please find yours..'))
 global arena
    root = arena.getrootdir;
            modelFolder = fullfile(root,'UserData','PredictionModels');
 [filename,pathname] = uigetfile(fullfile(modelFolder,'*.mat'));
 load(fullfile(pathname,filename),'mdl');
 mdl.LOOCV



end

