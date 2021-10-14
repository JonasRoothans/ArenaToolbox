function install_InterferenceHistogram(menuhandle,eventdata,scene)


menuInterferenceHistogram= scene.addon_addmenuitem('InterferenceHistogram','Fibers with Mesh');
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference of a Mesh with all loaded Fibers',str2func('@MeshInterference'),menuInterferenceHistogram)
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference of a Fiber with all loaded Meshes',str2func('@FiberInterference'),menuInterferenceHistogram)


menuhandle.Text = menuhandle.Text(6:end); %why 6?
disp('Docking complete')

end