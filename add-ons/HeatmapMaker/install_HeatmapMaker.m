function install_HeatmapMaker(menuhandle,eventdata,scene)


menuWithRecipe = scene.addon_addmenuitem('HeatmapMaker','Basic pipeline (exploratory)');
scene.addon_addmenuitem('HeatmapMaker','1. Make recipe template from nii',str2func('@HeatmapMaker_makerecipe'),menuWithRecipe)
scene.addon_addmenuitem('HeatmapMaker','2. Cook a heatmap',str2func('@HeatmapMaker_cook'),menuWithRecipe)
scene.addon_addmenuitem('HeatmapMaker','3a. (Dirty) Regression',str2func('@HeatmapMaker_regress'),menuWithRecipe)
scene.addon_addmenuitem('HeatmapMaker','3b. Leave One Out Cross Validation',str2func('@HeatmapMaker_LOOCV'),menuWithRecipe)

prediction = scene.addon_addmenuitem('HeatmapMaker','Advanced pipeline (LOO)');
scene.addon_addmenuitem('HeatmapMaker','Train a prediction algorithm (LOO)',str2func('@HeatmapMaker_trainPrediction'),prediction)
scene.addon_addmenuitem('HeatmapMaker','Predict a cohort',str2func('@HeatmapMaker_applyPrediction'),prediction)


other = scene.addon_addmenuitem('HeatmapMaker','Other');
scene.addon_addmenuitem('HeatmapMaker','Repair recipe',str2func('@HeatmapMaker_repairRecipe'),other)
scene.addon_addmenuitem('HeatmapMaker','ttest without recipe',str2func('@HeatmapMaker_ttest'),other)

legacy = scene.addon_addmenuitem('HeatmapMaker','Legacy (sweetspotstation)');
scene.addon_addmenuitem('HeatmapMaker','Make a Suretune based recipe',str2func('@HeatmapMaker_XX'),legacy)




menuhandle.Text = menuhandle.Text(6:end);
disp('Docking complete')

end