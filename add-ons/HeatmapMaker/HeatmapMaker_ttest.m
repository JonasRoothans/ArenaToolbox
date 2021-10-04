function [outputArg1,outputArg2] = sweetspotstation_makerecipe(menu,eventdata,scene)
%SWEETSPOTSTATION_MAKERECIPE Summary of this function goes here
%   Detailed explanation goes here


          
Stack = VoxelDataStack;
Stack.loadDataFromFolder();

if isempty(Stack.Voxels)
    disp('aborted by user')
    return
end

[folder,nameSuggestion,~] = fileparts(Stack.RecipePath);
UserInput = inputdlg({'HeatmapName','Description'},...
              'Heatmap maker', [1 50; 3 50],...
              {nameSuggestion,''}); 


try          
title = UserInput{1};
description = UserInput{2};
catch
end

disp('Converting stack to heatmap.. this may take some minutes')
heatmap = Stack.convertToHeatmapBasedOnVoxelValues(title,description);
heatmap.Tag = nameSuggestion;
disp('saving....')
mkdir(fullfile(folder,nameSuggestion,'output'));
heatmap.save(fullfile(folder,nameSuggestion,'output',nameSuggestion))
heatmap.Signedpmap.savenii(fullfile(folder,nameSuggestion,'output','signedpmap.nii'))
heatmap.Tmap.savenii(fullfile(folder,nameSuggestion,'output','Tmap.nii'))
heatmap.Pmap.savenii(fullfile(folder,nameSuggestion,'output','Pmap.nii'))
heatmap.Amap.savenii(fullfile(folder,nameSuggestion,'output','Amap.nii'))

assignin('base','heatmap',heatmap)
disp('heatmap is saved to harddisk and is available in workspace as ''heatmap''')



end

