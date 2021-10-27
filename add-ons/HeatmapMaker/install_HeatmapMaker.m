function install_HeatmapMaker(menuhandle,eventdata,scene)


menuWithRecipe = scene.addon_addmenuitem('HeatmapMaker','"Weighted" VTA based pipeline');
scene.addon_addmenuitem('HeatmapMaker','1. Make recipe template from nii',str2func('@HeatmapMaker_makerecipe'),menuWithRecipe)
scene.addon_addmenuitem('HeatmapMaker','2. Cook a heatmap',str2func('@HeatmapMaker_cook'),menuWithRecipe)
scene.addon_addmenuitem('HeatmapMaker','3a. Dirty Regression',str2func('@HeatmapMaker_dirty'),menuWithRecipe)
scene.addon_addmenuitem('HeatmapMaker','3b. Leave One Out Cross Validation',str2func('@HeatmapMaker_LOOCV'),menuWithRecipe)


basedOnVoxelValue = scene.addon_addmenuitem('HeatmapMaker','Voxel value based pipeline');
scene.addon_addmenuitem('HeatmapMaker','Heatmap from nii files in 1 folder',str2func('@HeatmapMaker_ttest'),basedOnVoxelValue)

other = scene.addon_addmenuitem('HeatmapMaker','Other');
scene.addon_addmenuitem('HeatmapMaker','Repair recipe',str2func('@HeatmapMaker_repairRecipe'),other)

legacy = scene.addon_addmenuitem('HeatmapMaker','Legacy (sweetspotstation)');
scene.addon_addmenuitem('HeatmapMaker','Make a Suretune based recipe',str2func('@HeatmapMaker_XX'),legacy)

prediction = scene.addon_addmenuitem('HeatmapMaker','Prediction');
scene.addon_addmenuitem('HeatmapMaker','Train a prediction algorithm',str2func('@HeatmapMaker_trainPrediction'),prediction)
scene.addon_addmenuitem('HeatmapMaker','Predict a cohort',str2func('@HeatmapMaker_XX'),prediction)



menuhandle.Text = menuhandle.Text(6:end);
disp('Docking complete')

end