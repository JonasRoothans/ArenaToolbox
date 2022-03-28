function MeshInterference(menuhandle,eventdata,scene)

    % Ask which Mesh to use, only allow Meshes
    labels= {};
    actor_idx = [];
    cmap = [];
    for iActor = 1:numel(scene.Actors)
        thisActor = scene.Actors(iActor);
        if  strcmp(class(thisActor.Data),'Mesh')
            labels{end+1} = thisActor.Tag;
            actor_idx(end+1) = iActor;
        end
    end
    [indx,tf] = listdlg('PromptString',{'Select the Mesh'},'ListString',labels);
    interfering_mesh = scene.Actors(actor_idx(indx));
    
        %dialog box
    prompt = {sprintf('You are calculating the interference of \n  %s \nwith all loaded Fibers. Please enter the corresponding clinical outcome(%%): ',interfering_mesh.Tag)};
    dlgtitle = 'Mesh vs all laoded Fibers';
    definput = {num2str(max([-100, 100]))};
    dims = [1 80];
    opts.Interpreter = 'tex';
    clinical_outcome = inputdlg(prompt,dlgtitle,dims,definput,opts);
    clinical_outcome = str2num(clinical_outcome{1});
    
    % get sampling and threshold from user
    [samplingMethod,weight_thresh] = get_sampling_and_threshold();
    if numel(interfering_mesh)==1
    [hit_list,fiber_list,cmap] =  interference_allTracts(interfering_mesh,scene,samplingMethod,weight_thresh);
    
    mesh_name = strjoin(regexp(interfering_mesh.Tag,'(\_|\.)','split'));
    fig = figure('Name',sprintf('Clinical Outcome vs Fibers hit for %s',mesh_name));
    title = strcat("Improvement of clinical outcome: ",num2str(clinical_outcome),"%")
    plot_histo(fig,title, hit_list,fiber_list, cmap)
    else
        meshes={};
        fibersLoaded={};
        FibersHit=[];
        for iMesh=1:numel(interfering_mesh)
            Themesh=interfering_mesh(iMesh)
            [hit_list,fiber_list,cmap] =  interference_allTracts(Themesh,scene,samplingMethod,weight_thresh);
            mesh_name = strjoin(regexp(interfering_mesh(iMesh).Tag,'(\_|\.)','split'));
            meshes{iMesh}=mesh_name;
            fibersLoaded=fiber_list;
            FibersHit(:,iMesh)=hit_list;
        end
        FibersHit=num2cell(FibersHit',1);
        T=table(meshes(:),FibersHit{:}, 'VariableNames', {'ROI', fibersLoaded{:}});
        
        % save results
        global arena
        root = arena.getrootdir;
        outputdirectory=load(fullfile(root,'histoConfig.mat'));
        outputdirectory=outputdirectory.results;
        formatOut = 'yyyy_mm_dd';
        disp(['saving as: ',datestr(now,formatOut),'_','Clinical Outcome vs Fibers hit for meshes',' in ..',outputdirectory])
        writetable(T,fullfile(outputdirectory,[datestr(now,formatOut),'_','Clinical Outcome vs Fibers hit for meshes.xlsx']));
        disp('Saving complete')
        
        
        
        
end
 
    

