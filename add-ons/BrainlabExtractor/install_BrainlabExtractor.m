function install_BrainlabExtractor(menuhandle,eventdata,scene)


scene.addon_addmenuitem('BrainlabExtractor','Normalize and extract Burned-in images with SPM',str2func('@BrainlabExtractor_normalize_and_extract'))
menuhandle.Text = menuhandle.Text(6:end);
disp('Docking complete')

end