function install_HeatmapMaker(menuhandle,eventdata,scene)


scene.addon_addmenuitem('HeatmapMaker','1. Make recipe template from nii',str2func('@HeatmapMaker_makerecipe'))
scene.addon_addmenuitem('HeatmapMaker','2. Cook a heatmap',str2func('@HeatmapMaker_cook'))
scene.addon_addmenuitem('HeatmapMaker','-> Voxel-value driven heatmap based on nii files in folder',str2func('@HeatmapMaker_ttest'))
menuhandle.Text = menuhandle.Text(6:end);
disp('Docking complete')

end