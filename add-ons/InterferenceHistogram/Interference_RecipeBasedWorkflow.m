function [outputArg1,outputArg2] = Interference_RecipeBasedWorkflow(menuhandle,eventdata,scene)
%INTERFERENCE_RECIPEBASEDWORKFLOW Summary of this function goes here


global arena
root = arena.getrootdir;
histoConfig = load(fullfile(root,'histoConfig.mat'));
vtk_path = histoConfig.VTKdir ;
results_path = histoConfig.results;
    
    folder_name = fullfile(vtk_path,'**/*.vtk');
    vtk_files = A_getfiles(folder_name); %all vtk files
    loaded_actors = {scene.Actors.Tag};
    roi_names = {vtk_files.name};
    for ifile=1:length(vtk_files)
        filename = fullfile(vtk_files(ifile).folder,vtk_files(ifile).name);
        
        %don't load fibers twice
        if not(ismember(vtk_files(ifile).name(1:end-4),loaded_actors))
            scene.CallFromOutside.import_vtk(scene,filename,'some');
        end
    end






end

