function install_InterferenceHistogram(menuhandle,eventdata,scene)

global arena;
root = arena.getrootdir;
if not(isfile(fullfile(root,'histoConfig.mat')))
    waitfor(msgbox('Please set the path to the VTK files for the fibers'))
    vtk_path = uigetdir('Please set the path to the VTK files for the fibers')
    histoConfig.VTKdir = vtk_path;
    waitfor(msgbox('Please set the path to store the results'))
    results_path = uigetdir('Please set the path to store the results')
    histoConfig.results = results_path;
    if  isnumeric(histoConfig.VTKdir) || isnumeric(histoConfig.results)
        error('error setting required paths, please repeat process and do not cancel any of the windows')
    else
    save(fullfile(root,'histoConfig.mat'),'-struct','histoConfig')
    end
else
    histoConfig=load(fullfile(root,'histoConfig.mat'));
    if isempty(histoConfig.VTKdir) || ~isfolder(histoConfig.VTKdir)
        waitfor(msgbox('please choose the location of the fibers folder in the following window'));
        histoConfig.VTKdir = uigetdir(root,'Please set the path to the VTK files for the fibers');
    end
    if isempty(histoConfig.results) || ~(contains(histoConfig.results, root))
        waitfor(msgbox('please choose where do you want to save the results of fiber interference'));
        histoConfig.results=uigetdir(root,'Please set the path to store the results');
    end
    if  isnumeric(histoConfig.VTKdir) || isnumeric(histoConfig.results)
        error('error setting required paths, please repeat process and do not cancel any of the windows')
    else
    save(fullfile(root,'histoConfig.mat'),'-struct','histoConfig')
    end
end



menuInterferenceHistogramSingle= scene.addon_addmenuitem('InterferenceHistogram','Single: Fibers with Mesh');
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference of a Mesh with all loaded Fibers',str2func('@MeshInterference'),menuInterferenceHistogramSingle)
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference of a Fiber with all loaded Meshes',str2func('@FiberInterference'),menuInterferenceHistogramSingle)

menuInterferenceHistogramAll= scene.addon_addmenuitem('InterferenceHistogram','All: Fibers with Meshes');
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference of all Fibers',{str2func('@Interference'),'all'},menuInterferenceHistogramAll)
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference with basalganglia fibers',{str2func('@Interference'),'basalganglia'},menuInterferenceHistogramAll)
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference with motorcortex fibers',{str2func('@Interference'),'motorcortex'},menuInterferenceHistogramAll)
scene.addon_addmenuitem('InterferenceHistogram','Calculate Interference with prefrontalcortex fibers',{str2func('@Interference'),'prefrontalcortex'},menuInterferenceHistogramAll)

menuInterferenceHistogramFlo= scene.addon_addmenuitem('InterferenceHistogram','Flo-workflow');
scene.addon_addmenuitem('InterferenceHistogram','Create recipe (using heatmapmaker add-on)','@Interference_recipeportal',menuInterferenceHistogramFlo);
scene.addon_addmenuitem('InterferenceHistogram','Run interference on all',str2func('@InterferenceFlo'),menuInterferenceHistogramFlo);


menuhandle.Text = menuhandle.Text(6:end); 
disp('Docking complete')

end