function [outputArg1,outputArg2] = HeatmapMaker_exportLeftRightElectrodeToRecipe(menu,eventdata,scene)
%HEATMAPMAKER_EXPORTLEFTRIGHTELECTRODETORECIPE Summary of this function goes here
%   Detailed explanation goes here

SUBFOLDERNAME = 'subfolder';

waitfor(msgbox('Select outputfolder (a subfolder will be created and filled with all electrodes in this scene)'))
parent_folder = uigetdir();


for iActor = 1:numel(scene.Actors)
    thisActor = scene.Actors(iActor);
    if isa(thisActor.Data,'Electrode')
        %--custom name?
        if not(strcmp(thisActor.Data.VTA.Tag,''))
            SUBFOLDERNAME = thisActor.Data.VTA.Tag;
        end
        output_folder = fullfile(parent_folder,SUBFOLDERNAME);
        if ~exist(output_folder,'dir')
            mkdir(output_folder)
        end
        
        
        thisActor.Data.Space = Space.MNI2009b;
        copy_Actor = thisActor.Data.copy();
        copy_Actor.VTA = VTA.empty();
        copy_Actor.saveToFolder(output_folder,thisActor.Tag)
        
        

        
        if numel(thisActor.Data.VTA) == 1
            thisActor.Data.VTA.Volume.Source.makeBinary(max(thisActor.Data.VTA.Volume.Source.Voxels(:))/2).saveToFolder(output_folder,thisActor.Tag)
        else
            dummyVTA = thisActor.Data.makeVTA('Medtronic33891False90c1 0 0 0a0 0 0 0.mat');
            dummyVTA.Volume.saveToFolder(output_folder,['DUMMY_',thisActor.Tag])
        end
    end
end

T = table;
T.folderID{1,1} = SUBFOLDERNAME;
T.fullpath{1,1} = output_folder;
T.ENTER_SCORE_LABEL_AND_VALUES(1,1) = 0;
T. Move_or_keep_left(1,1) = 1;
writetable(T,fullfile(parent_folder,'recipe.xlsx'))
Done;
disp(['--> Recipe is saved in: ',parent_folder]);
disp('BE AWARE THIS STEP HAS SET ALL SPACES TO MNI. IF THIS IS NOT THE CASE, ANY ANALYSIS WILL BE INVALID')