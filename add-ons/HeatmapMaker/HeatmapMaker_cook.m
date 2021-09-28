function [outputArg1,outputArg2] = sweetspotstation_makerecipe(menu,eventdata,scene)
%SWEETSPOTSTATION_MAKERECIPE Summary of this function goes here
%   Detailed explanation goes here


          
Stack = VoxelDataStack;
Stack.loadStudyDataFromRecipe();

if isempty(Stack.Voxels)
    disp('aborted by user')
    return
end
[folder,nameSuggestion,~] = fileparts(fileparts(Stack.RecipePath));
UserInput = inputdlg({'HeatmapName','Description'},...
              'Heatmap maker', [1 50; 3 50],...
              {nameSuggestion,''}); 


try          
title = UserInput{1};
description = UserInput{2};
catch
end

disp('Converting stack to heatmap.. this may take some minutes')
heatmap = Stack.convertToHeatmap(title,description);
heatmap.Tag = nameSuggestion;
disp('saving....')
heatmap.Signedpmap.savenii(fullfile(folder,nameSuggestion,'signedpmap.nii'))

assignin('base','heatmap',heatmap)
disp('heatmap is saved to harddisk and is available in workspace as ''heatmap''')



end

