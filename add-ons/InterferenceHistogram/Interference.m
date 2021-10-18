function Interference(menuhandle,eventdata,roi,scene)
    

 % get all meshes - ask for clinical outcome
    mesh_labels= {};
    mesh_idx = [];
    for iActor = 1:numel(scene.Actors)
        thisActor = scene.Actors(iActor);
        if  strcmp(class(thisActor.Data),'Mesh')
            mesh_labels{end+1} = thisActor.Tag;
            mesh_idx(end+1) = iActor;
        end
    end
        %dialog box
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
    
    %set sampling method an tracts - if mesh.Data.Source is empty the
    %sampling method is overwritten to Check if fiber hits mesh
    [samplingMethod,weight_thresh] = get_sampling_and_threshold()

    
    
    %load all Tracts
    if strcmp(roi,'all'); roi='**';end;
    import_vtk(scene,roi);


    %Mesh interference for all loaded meshes
    subplot_rows = (ceil(mesh_idx/2))
    y = [];
    x = [,];
    for iMesh = 1:length(mesh_idx)
        interfering_mesh = scene.Actors(mesh_idx(iMesh));
        if isempty(interfering_mesh.Data.Source)
            samplingMethod = 'Check if fiber hits mesh';
            map = [];
        else
            map = interfering_mesh.Data.Source;
        end
        [hit_list,fiber_list] = interference_allTracts(map,interfering_mesh,scene,samplingMethod,weight_thresh,clinical_outcome(iMesh));
        y(end+1,:) = clinical_outcome(iMesh)
        x(end+1,:)= hit_list
    end
    y=y.'
    b = regress(y,x)
    for i=1:length(fiber_list)
    fprintf("%s :    %f.3\n",fiber_list{i},b(i))
    end
end



function import_vtk(scene,roi) %make options: all, BG, Motorcortex , PFC

    folder_name = strcat('vtk_files_v1/',roi,'/*.vtk');
    vtk_files = dir(folder_name); %all vtk files
    loaded_actors = {scene.Actors.Tag}
    for ifile=1:length(vtk_files)
        filename = strcat(vtk_files(ifile).folder,'/',vtk_files(ifile).name)
        
        %don't load fibers twice
        if ismember( vtk_files(ifile).name(1:end-4),loaded_actors) 
            continue
        end 

        disp('loading a VTK with a custom script. (debug: ArenaScene / import_vtk)')
        fid = fopen(filename);
        tline = fgetl(fid);
        V = [];
        Fib = {};
        %read the file:
            while ischar(tline)
               nums = str2num(tline);
                    if length(nums)==3 %3D coordinate
                           V(end+1,:) = nums;
                    elseif length(nums)==0 %Text
                            disp(tline)
                    elseif length(nums)==nums(1)+1 %Fiber
                            Fib{end+1} = nums(2:end)+1;
                    end
                    tline = fgetl(fid);
            end
            fclose(fid);
            %show the fibers
            f = Fibers;

            for i = 1:numel(Fib)
                points = V(Fib{i},:);
                pc = points;
                f.addFiber(pc,i);
            end

            actor = f.see(scene,100);
            [pn,fn] = fileparts(filename);
            actor.changeName(fn);
     
    end
end

function [samplingMethod,weight_thresh] = get_sampling_and_threshold()  % ask for sampling method    

    options = {'Min value','Max value','Average Value','Sum','Check if fiber hits mesh'};
    [indx,tf] = listdlg('PromptString',{'Select method'},'ListString',options);
    samplingMethod = options{indx};
    
    % set treshold for weights
    if strcmp(samplingMethod,'Sum')
        prompt = {sprintf('Please enter the threshold of points hit:')};
        dlgtitle = 'Set Threshold';
        definput = {num2str(min([0, 100]))}; 
        dims = [1 45];
        opts.Interpreter = 'tex';
        weight_thresh = inputdlg(prompt,dlgtitle,dims,definput,opts);
        weight_thresh = str2num(weight_thresh{1}); 
    end
    
end

function [hit_list,fiber_list] = interference_allTracts(map,interfering_mesh,scene,samplingMethod,weight_thresh,clinical_outcome)
    tag = interfering_mesh.Tag;
    mesh = interfering_mesh.Data;
    fig = figure('Name',sprintf('Clinical Outcome vs Fibers hit for %s',tag));

    hit_list = [];
    fiber_list = {};
    cmap = [];
    for iActor = 1:numel(scene.Actors)
    thisActor = scene.Actors(iActor);
        if  strcmp(class(thisActor.Data),'Fibers')
            interfering_fibers = thisActor

            %loop. First join all the fibers. For quick processing
            nVectorsPerFiber = arrayfun(@(x) length(x.Vectors),interfering_fibers.Data.Vertices);
            Vectors = Vector3D.empty(sum(nVectorsPerFiber),0); %empty allocation
            FiberIndices = [0,cumsum(nVectorsPerFiber)]+1;
            weights = [];
            fibIndex = 1;
            for iFiber = 1:numel(interfering_fibers.Data.Vertices)
                Vectors(FiberIndices(iFiber):FiberIndices(iFiber+1)-1) = interfering_fibers.Data.Vertices(iFiber).Vectors;
            end
            FiberIndices(iFiber+1) = length(Vectors)+1;


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
                        fprintf("%f of %f fibers from %s hit\n",sum(interfering_fibers.Data.Weight), numel(interfering_fibers.Data.Vertices),interfering_fibers.Tag)
            
                    case 'Average Value'
                        interfering_fibers.Data.Weight(iFiber) = mean(weights);
                    case 'Sum'
                        interfering_fibers.Data.Weight(iFiber) = nansum(weights);

                end
            end
            %interfering_fibers.changeSetting('colorByWeight',true);
            Done;
            switch samplingMethod
                case {'Max value','Check if fiber hits mesh'}
                    fprintf("%f of %f fibers from %s hit\n",sum(interfering_fibers.Data.Weight), numel(interfering_fibers.Data.Vertices),interfering_fibers.Tag)
                    percentage_hit =  sum(interfering_fibers.Data.Weight)/numel(interfering_fibers.Data.Vertices);
                case 'Sum'
                    fprintf("%.2f of %.0f fibers from %s hit at at least %i points\n",sum(interfering_fibers.Data.Weight>weight_thresh), numel(interfering_fibers.Data.Vertices),interfering_fibers.Tag,weight_thresh)
                    percentage_hit =  sum(interfering_fibers.Data.Weight>weight_thresh)/numel(interfering_fibers.Data.Vertices);
            end
            hit_list(end +1,:) = [percentage_hit*100];
            fiber_list{end +1} = interfering_fibers.Tag;
            cmap(end+1,:) = interfering_fibers.Visualisation.settings.colorFace2;
        end
    end
    
    

    b = bar(hit_list,'facecolor','flat');
    b.CData = cmap
    title(strcat("Improvement of clinical outcome: ",num2str(clinical_outcome),"%"))
    ax = gca
    set(ax,'XTickLabel',fiber_list);
    ax.FontSize =16
    xtickangle(40)
    ylim([0 105])
    ylabel('Percentage of fibers interfering with the lesion (%)');
    hold off
end
    
