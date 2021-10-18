function install_InterferenceHistogram(menuhandle,eventdata,scene)


menuInterferenceHistogram= scene.addon_addmenuitem('InterferenceHistogram','Single: Fibers with Mesh');
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference of a Mesh with all loaded Fibers',str2func('@MeshInterference'),menuInterferenceHistogram)
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference of a Fiber with all loaded Meshes',str2func('@FiberInterference'),menuInterferenceHistogram)

menuInterferenceHistogram= scene.addon_addmenuitem('InterferenceHistogram','All: Fibers with Meshes');
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference of all Fibers',{str2func('@Interference'),'all'},menuInterferenceHistogram)
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference with basalganglia fibers',{str2func('@Interference'),'basalganglia'},menuInterferenceHistogram)
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference with motorcortex fibers',{str2func('@Interference'),'motorcortex'},menuInterferenceHistogram)
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference with prefrontalcortex fibers',{str2func('@Interference'),'prefrontalcortex'},menuInterferenceHistogram)



menuhandle.Text = menuhandle.Text(6:end); 
disp('Docking complete')

end