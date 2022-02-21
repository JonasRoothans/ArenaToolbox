function install_HeatmapMaker(menuhandle,eventdata,scene)


menuWithRecipe = scene.addon_addmenuitem('HeatmapMaker','Basic pipeline');
scene.addon_addmenuitem('HeatmapMaker','1. Make recipe template from nii',str2func('@HeatmapMaker_makerecipe'),menuWithRecipe)
scene.addon_addmenuitem('HeatmapMaker','2. Cook a heatmap',str2func('@HeatmapMaker_cook'),menuWithRecipe)
scene.addon_addmenuitem('HeatmapMaker','3. (Dirty) Regression',str2func('@HeatmapMaker_regress'),menuWithRecipe)
%scene.addon_addmenuitem('HeatmapMaker','3b. Leave One Out Cross Validation',str2func('@HeatmapMaker_LOOCV'),menuWithRecipe)

prediction = scene.addon_addmenuitem('HeatmapMaker','Advanced pipeline (LOO)');
scene.addon_addmenuitem('HeatmapMaker','Train a prediction algorithm (LOO)',str2func('@HeatmapMaker_trainPrediction'),prediction)
scene.addon_addmenuitem('HeatmapMaker','Predict a cohort',str2func('@HeatmapMaker_applyPrediction'),prediction)
scene.addon_addmenuitem('HeatmapMaker','Simulate Cross Validation (LOOCV)',str2func('@HeatmapMaker_LOOCV'),prediction)


other = scene.addon_addmenuitem('HeatmapMaker','Other');
scene.addon_addmenuitem('HeatmapMaker','Repair recipe',str2func('@HeatmapMaker_repairRecipe'),other)
scene.addon_addmenuitem('HeatmapMaker','ttest without clinical scores',str2func('@HeatmapMaker_ttest'),other)
scene.addon_addmenuitem('HeatmapMaker','Sort folder to subfolders per patient',str2func('@HeatmapMaker_sortPerPatient'),other)
scene.addon_addmenuitem('HeatmapMaker','Export Suretune Sessions to folder',str2func('@HeatmapMaker_SuretuneSessions'),other)

legacy = scene.addon_addmenuitem('HeatmapMaker','Legacy (sweetspotstation)');
scene.addon_addmenuitem('HeatmapMaker','Make a Suretune based recipe',str2func('@HeatmapMaker_XX'),legacy)




menuhandle.Text = menuhandle.Text(6:end);
disp('Docking complete')

end