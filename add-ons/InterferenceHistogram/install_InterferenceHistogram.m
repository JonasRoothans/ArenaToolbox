function install_InterferenceHistogram(menuhandle,eventdata,scene)

global arena;
root = arena.getrootdir;
loaded = load(fullfile(root,'config.mat'));
% Option 1 add to config.mat
% if not(ismember('VTKdir',fieldnames( loaded.config)))
%     f = msgbox('Pease set the path to the VTK files for the fibers')
%     vtk_path = uigetdir('Pease set the path to the VTK files for the fibers')
%     loaded.config.VTKdir = vtk_path;
%     save(fullfile(root,'config.mat'),'-struct','loaded')
% end

%Option 2 create global variable:
global config
config = loaded.config
config.VTKdir = '/Users/visualdbs/Documents/MATLAB/vtk_files_v1';


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