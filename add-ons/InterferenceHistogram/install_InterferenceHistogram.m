function install_InterferenceHistogram(menuhandle,eventdata,scene)

global arena;
root = arena.getrootdir;
if not(isfile(fullfile(root,'histoConfig.mat')))
    f = msgbox('Please set the path to the VTK files for the fibers')
    vtk_path = uigetdir('Please set the path to the VTK files for the fibers')
    histoConfig.VTKdir = vtk_path;
    f = msgbox('Please set the path to store the results')
    results_path = uigetdir('Please set the path to store the results')
    histoConfig.results = results_path;
    save(fullfile(root,'histoConfig.mat'),'-struct','histoConfig')
end



menuInterferenceHistogramSingle= scene.addon_addmenuitem('InterferenceHistogram','Single: Fibers with Mesh');
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference of a Mesh with all loaded Fibers',str2func('@MeshInterference'),menuInterferenceHistogramSingle)
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference of a Fiber with all loaded Meshes',str2func('@FiberInterference'),menuInterferenceHistogramSingle)

menuInterferenceHistogramAll= scene.addon_addmenuitem('InterferenceHistogram','All: Fibers with Meshes');
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference of all Fibers',{str2func('@Interference'),'all'},menuInterferenceHistogramAll)
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference with basalganglia fibers',{str2func('@Interference'),'basalganglia'},menuInterferenceHistogramAll)
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference with motorcortex fibers',{str2func('@Interference'),'motorcortex'},menuInterferenceHistogramAll)
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference with prefrontalcortex fibers',{str2func('@Interference'),'prefrontalcortex'},menuInterferenceHistogramAll)



menuhandle.Text = menuhandle.Text(6:end); 
disp('Docking complete')

end