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

expert = scene.addon_addmenuitem('HeatmapMaker','Expert pipeline');
scene.addon_addmenuitem('HeatmapMaker','1. Make a single patient recipe based on electrodes in scene',str2func('@HeatmapMaker_exportLeftRightElectrodeToRecipe'),expert)
scene.addon_addmenuitem('HeatmapMaker','2. Predict best settings based on TWO maps',str2func('@HeatmapMaker_monopolarReviewSE'),expert)


other = scene.addon_addmenuitem('HeatmapMaker','Other');
scene.addon_addmenuitem('HeatmapMaker','Repair recipe',str2func('@HeatmapMaker_repairRecipe'),other)
scene.addon_addmenuitem('HeatmapMaker','ttest without clinical scores',str2func('@HeatmapMaker_ttest'),other)
scene.addon_addmenuitem('HeatmapMaker','Sort folder to subfolders per patient',str2func('@HeatmapMaker_sortPerPatient'),other)
scene.addon_addmenuitem('HeatmapMaker','Export Suretune Sessions to folder',str2func('@HeatmapMaker_SuretuneSessions'),other)
scene.addon_addmenuitem('HeatmapMaker','extract all files and store in one folder',str2func('@HeatmapMaker_UnpackFolders'),other)
scene.addon_addmenuitem('HeatmapMaker','display all VTAs',str2func('@HeatmapMaker_show'),other)
scene.addon_addmenuitem('HeatmapMaker','convert ea_reconstruction to arena electrode',str2func('@HeatmapMaker_convertleaddbsreco'),other)
scene.addon_addmenuitem('HeatmapMaker','produce table with distances of VTAs to COG',str2func('@HeatmapMaker_DistanceToHotspot'),other)

legacy = scene.addon_addmenuitem('HeatmapMaker','Legacy (sweetspotstation)');
scene.addon_addmenuitem('HeatmapMaker','Make a Suretune based recipe',str2func('@HeatmapMaker_SuretuneSessionsRecipe'),legacy)

lazy = scene.addon_addmenuitem('HeatmapMaker','Lazy import',str2func('@HeatmapMaker_Lazy'));

hlazy=handle(lazy);it's 
hlazy.Separator = 'on';


menuhandle.Text = menuhandle.Text(6:end);
disp('Docking complete')

end