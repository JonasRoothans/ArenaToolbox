function [outputArg1,outputArg2] = HeatmapMaker_exportLeftRightElectrodeToRecipe(menu,eventdata,scene)
%HEATMAPMAKER_EXPORTLEFTRIGHTELECTRODETORECIPE Summary of this function goes here
%   Detailed explanation goes here

SUBFOLDERNAME = 'subfolder';

waitfor(msgbox('Select utputfolder (a subfolder will be created and filled with all electrodes in this scene)'))
parent_folder = uigetdir();
output_folder = fullfile(parent_folder,SUBFOLDERNAME);
mkdir(output_folder)

for iActor = 1:numel(scene.Actors)
    thisActor = scene.Actors(iActor);
    if isa(thisActor.Data,'Electrode')
        thisActor.Data.Space = Space.MNI2009b;
        thisActor.saveToFolder(output_folder)
        dummyVTA = thisActor.Data.makeVTA('Medtronic33891False90c1 0 0 0a0 0 0 0.mat');
        dummyVTA.Volume.saveToFolder(output_folder,thisActor.Tag)
    end
end

T = table;
T.folder_ID{1,1} = SUBFOLDERNAME;
T.fullpath{1,1} = output_folder;
T.ENTER_SCORE_LABEL_AND_VALUES(1,1) = 0;
T. Move_or_keep_left(1,1) = 1;
writetable(T,fullfile(parent_folder,'recipe.xlsx'))
Done;
disp(['--> Recipe is saved in: ',parent_folder]);
disp('BE AWARE THIS STEP HAS SET ALL SPACES TO MNI. IF THIS IS NOT THE CASE, ANY ANALYSIS WILL BE INVALID')