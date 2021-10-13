function install_InterferenceHistogram(menuhandle,eventdata,scene)


menuInterferenceHistogram= scene.addon_addmenuitem('InterferenceHistogram','All Fibers with Mesh');
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interfrence of Selection with all loaded Fibers',str2func('@FiberInterference'),menuInterferenceHistogram)


menuhandle.Text = menuhandle.Text(6:end); %why 6?
disp('Docking complete')

end