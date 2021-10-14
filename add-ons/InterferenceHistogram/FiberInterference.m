function FiberInterference(menuhandle,eventdata,scene)
    hit_list = [];
    mesh_list = {};


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
% ask for sampling method    

    options = {'Min value','Max value','Average Value','Sum','Check if fiber hits mesh'};
    [indx,tf] = listdlg('PromptString',{'Select method'},'ListString',options);
    samplingMethod = options{indx};
    

    if strcmp(samplingMethod,'Sum')
        
        prompt = {sprintf('Please enter the threshold of points hit:')};
        dlgtitle = 'Set Threshold';
        definput = {num2str(min([0, 100]))}; % what should be max value?
        dims = [1 45];
        opts.Interpreter = 'tex';
        weight_thresh = inputdlg(prompt,dlgtitle,dims,definput,opts);
        weight_thresh = str2num(weight_thresh{1});

    end
      
    %loop. First join all the fibers. For quick processing
    nVectorsPerFiber = arrayfun(@(x) length(x.Vectors),interfering_fibers.Data.Vertices);
    Vectors = Vector3D.empty(sum(nVectorsPerFiber),0); %empty allocation
    FiberIndices = [0,cumsum(nVectorsPerFiber)]+1;
    for iFiber = 1:numel(interfering_fibers.Data.Vertices)
        Vectors(FiberIndices(iFiber):FiberIndices(iFiber+1)-1) = interfering_fibers.Data.Vertices(iFiber).Vectors;
    end
    FiberIndices(iFiber+1) = length(Vectors)+1;
            
            
    %calculate interference for every loaded mesh
    mesh_idx = 0;
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
    
        %sample the map
        switch samplingMethod
            case 'Check if fiber hits mesh'
                mapvalue = mesh.isInside(Vectors);
            otherwise
                mapvalue = map.getValueAt(PointCloud(Vectors));
        end

        for iFiber = 1:numel(interfering_fibers.Data.Vertices)
            weights = mapvalue(FiberIndices(iFiber):FiberIndices(iFiber+1)-1);
            switch samplingMethod
                case 'Min value'
                    interfering_fibers.Data.Weight(iFiber) = min(weights);
                case {'Max value','Check if fiber hits mesh'}
                    interfering_fibers.Data.Weight(iFiber) = max(weights);
                case 'Average Value'
                    interfering_fibers.Data.Weight(iFiber) = mean(weights);
                case 'Sum'
                    interfering_fibers.Data.Weight(iFiber) = nansum(weights);
            end
        end
        interfering_fibers.changeSetting('colorByWeight',true);
        Done;
        switch samplingMethod
            case {'Max value','Check if fiber hits mesh'}
                fprintf("%f of %f fibers from %s hit\n",sum(interfering_fibers.Data.Weight), numel(interfering_fibers.Data.Vertices),interfering_mesh.Tag)
                percentage_hit =  sum(interfering_fibers.Data.Weight)/numel(interfering_fibers.Data.Vertices);
            case 'Sum'
                fprintf("%.2f of %.0f fibers from %s hit at at least %i points\n",sum(interfering_fibers.Data.Weight>weight_thresh), numel(interfering_fibers.Data.Vertices),interfering_mesh.Tag,weight_thresh)
                percentage_hit =  sum(interfering_fibers.Data.Weight>weight_thresh)/numel(interfering_fibers.Data.Vertices);
        end
        hit_list(end +1,:) = [percentage_hit*100, clinical_outcome(mesh_idx)];
        mesh_list{end +1} = interfering_mesh.Tag;
    end
    histo = figure('Name',sprintf('Clinical Outcome vs Fibers hit for %s',interfering_fibers.Tag));
    b = bar(hit_list);
    set(b, {'DisplayName'}, {'Fibers Hit', 'Clinical Outcome'}')
    ylim([0 100])
    legend()
    set(gca,'XTickLabel',mesh_list);
    ylabel('Percentage of clinical improvement and fibers overlapping with the lesion (%)');
end
 
    

