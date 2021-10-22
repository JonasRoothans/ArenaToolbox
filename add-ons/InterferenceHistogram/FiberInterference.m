function FiberInterference(menuhandle,eventdata,scene)
    hit_list = [];
    mesh_list = {};
    cmap = [];
 %%%TO DO: integrate existing functions!

    % Ask which Fibers to use, only allow Fibers
    labels= {};
    actor_idx = [];
    all_meshes = {};
    for iActor = 1:numel(scene.Actors)
        thisActor = scene.Actors(iActor);
        if  strcmp(class(thisActor.Data),'Fibers')
            labels{end+1} = thisActor.Tag;
            actor_idx(end+1) = iActor;
        elseif strcmp(class(thisActor.Data),'Mesh')
            all_meshes{end+1} = thisActor.Tag;  
        end
    end
    [indx,tf] = listdlg('PromptString',{'Select the Fibers of interest'},'ListString',labels);
    interfering_fibers = scene.Actors(actor_idx(indx));
   
    
    %dialog box
    prompt = {sprintf('You are calculating the interference of \n  %s \nwith all loaded Meshes. Please enter the corresponding clinical outcome(%%) for the follwing Meshes: \n 1. %s',interfering_fibers.Tag, all_meshes{1})};
    dlgtitle = 'Mesh vs all laoded Fibers';
    definput = {num2str(max([-100, 100]))};
    dims = [1 80];
    opts.Interpreter = 'tex';
    if length(all_meshes)>1
            for i=2:length(all_meshes)
                prompt{end +1} = sprintf('%i. %s',i,all_meshes{i})
                definput{end +1} = definput{1};
                dims(end +1,:) = dims(1,:);
            end
    end
    clinical_outcome = inputdlg(prompt,dlgtitle,dims,definput,opts);
    clinical_outcome = cellfun(@str2num,clinical_outcome);

    [samplingMethod,weight_thresh] = get_sampling_and_threshold()
      
    %loop. First join all the fibers. For quick processing
    nVectorsPerFiber = arrayfun(@(x) length(x.Vectors),interfering_fibers.Data.Vertices);
    Vectors = Vector3D.empty(sum(nVectorsPerFiber),0); %empty allocation
    FiberIndices = [0,cumsum(nVectorsPerFiber)]+1;
    for iFiber = 1:numel(interfering_fibers.Data.Vertices)
        Vectors(FiberIndices(iFiber):FiberIndices(iFiber+1)-1) = interfering_fibers.Data.Vertices(iFiber).Vectors;
    end
    FiberIndices(iFiber+1) = length(Vectors)+1;
            
            
    %calculate interference for every loaded mesh
    mesh_idx = 0
    for iActor = 1:numel(scene.Actors)
        thisActor = scene.Actors(iActor);
        if  strcmp(class(thisActor.Data),'Mesh')
            interfering_mesh = thisActor
            mesh_idx  = mesh_idx +  1
        else
            continue
        end
        
        if strcmp(samplingMethod,'Check if fiber hits mesh')
            map = [];
            mesh = interfering_mesh.Data;
        else
            map = interfering_mesh.Data.Source;
            mesh = interfering_mesh.Data;
        end
    
        
        scene.CallFromOutside.fiberMapInterference(map,samplingMethod,interfering_fibers)
        
        
        switch samplingMethod
            case {'Max value','Check if fiber hits mesh'}
                fprintf("%f of %f fibers from %s hit\n",sum(interfering_fibers.Data.Weight), numel(interfering_fibers.Data.Vertices),interfering_mesh.Tag)
                percentage_hit =  sum(interfering_fibers.Data.Weight)/numel(interfering_fibers.Data.Vertices);
            case 'Sum'
                fprintf("%.2f of %.0f fibers from %s hit at at least %i points\n",sum(interfering_fibers.Data.Weight>weight_thresh), numel(interfering_fibers.Data.Vertices),interfering_mesh.Tag,weight_thresh)
                percentage_hit =  sum(interfering_fibers.Data.Weight>weight_thresh)/numel(interfering_fibers.Data.Vertices);
        end
        hit_list(end+1) = [percentage_hit*100];
        mesh_list{end +1} = strjoin(regexp(interfering_mesh.Tag,'(\_|\.)','split'));
        cmap(end+1,:) = interfering_mesh.Visualisation.settings.colorFace;
    end
    
    fiber_name = strjoin(regexp(interfering_fibers.Tag,'(\_|\.)','split'));
    fig = figure('Name',sprintf('Interference of the %s',fiber_name));
    title_name = ['Fiber intereference of the %s with all loaded meshes',fiber_name]
    plot_histo(fig,title_name, hit_list,mesh_list, cmap)
end
 
    

