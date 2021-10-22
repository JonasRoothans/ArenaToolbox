function Interference(menuhandle,eventdata,roi,scene)


    % get all meshes 
    mesh_labels= {};
    mesh_idx = [];
    for iActor = 1:numel(scene.Actors)
        thisActor = scene.Actors(iActor);
        if  strcmp(class(thisActor.Data),'Mesh')
            mesh_labels{end+1} = strjoin(regexp(thisActor.Tag,'(\_|\.)','split'));
            mesh_idx(end+1) = iActor;
        end
    end
    
    %dialog box - ask for clinical outcome
    prompt = {sprintf('You are calculating the interference of \n  %s Fibers \nwith all loaded Meshes. Please enter the corresponding clinical outcome(%%) for the follwing Meshes: \n 1. %s',roi, mesh_labels{1})};
    dlgtitle = 'Meshes vs Fibers';
    definput = {num2str(max([-100, 100]))};
    dims = [1 80];
    opts.Interpreter = 'tex';
    if length(mesh_idx)>1
            for i=2:length(mesh_idx)
                prompt{end +1} = sprintf('%i. %s',i,mesh_labels{i});
                definput{end +1} = definput{1};
                dims(end +1,:) = dims(1,:);
            end
    end
    clinical_outcome = inputdlg(prompt,dlgtitle,dims,definput,opts);
    clinical_outcome = cellfun(@str2num,clinical_outcome);
    
    %set sampling method and threshold - if mesh.Data.Source is empty the
    %sampling method is overwritten to "Check if fiber hits mesh"
    [samplingMethod,weight_thresh] = get_sampling_and_threshold();
    
    
    %load all Tracts
    % Option 1 acces via config.mat file
    % global arena
    % root = arena.getrootdir;
    % loaded = load(fullfile(root,'config.mat'))
    % vtk_path = loaded.config.VTKdir 


    % Option 2 acces via global variable
    global config
    vtk_path = config.VTKdir

    
    
    
    if strcmp(roi,'all'); roi='**';end;
    folder_name = fullfile(vtk_path,roi,'/*.vtk');
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

    
    %Mesh interference for all loaded meshes
    mesh_list = [];
    y = [];
    x = [];
    scene_fig = gcf;
    for iMesh = 1:length(mesh_idx)
        interfering_mesh = scene.Actors(mesh_idx(iMesh));
        [hit_list,fiber_list,cmap] = interference_allTracts(interfering_mesh,scene,samplingMethod,weight_thresh,roi_names);
        y(end+1,:) = clinical_outcome(iMesh);
        x(end+1,:)= hit_list;
        mesh_name = strjoin(regexp(interfering_mesh.Tag,'(\_|\.)','split'));
        
        mesh_list{end+1} = mesh_name
        
        fig = figure('Name',sprintf('Clinical Outcome vs Fibers hit for %s',mesh_name));
        title_name = strcat("Improvement of clinical outcome: ",num2str(clinical_outcome(iMesh)),"%")
        plot_histo(fig,title_name, hit_list,fiber_list, cmap)
        figure(scene_fig); % set current figure
        

    end
    %save as xls 
    interference_results = cat(2,y,x);
    writetable(array2table(interference_results,'RowNames',mesh_list,'VariableNames',['improvement',fiber_list]),strcat(scene.Title,'_interference.xls'),'WriteRowNames',true');

    regression_results = regress(y,x);
    
    writetable(array2table(transpose(regression_results),'VariableNames',fiber_list),strcat(scene.Title,'_regression.xls'));

    for i=1:length(fiber_list)
    fprintf("%s :    %f.3\n",fiber_list{i},regression_results(i))
    end
end






