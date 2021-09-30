function install_HeatmapMaker(menuhandle,eventdata,scene)


scene.addon_addmenuitem('HeatmapMaker','1. Make recipe template from nii',str2func('@HeatmapMaker_makerecipe'))
scene.addon_addmenuitem('HeatmapMaker','2. Cook a heatmap',str2func('@HeatmapMaker_cook'))
scene.addon_addmenuitem('HeatmapMaker','-> Simple ttest on folder of nii files',str2func('@HeatmapMaker_ttest'))
menuhandle.Text = menuhandle.Text(6:end);
disp('Docking complete')

end