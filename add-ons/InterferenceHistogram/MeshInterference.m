function FiberInterference(menuhandle,eventdata,scene)
    hit_list = [];
    fiber_list = {};


    % Ask which Mesh to use, only allow Meshes
    labels= {};
    actor_idx = [];
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
    definput = {num2str(min([-100, 100]))};
    dims = [1 80];
    opts.Interpreter = 'tex';
    clinical_outcome = inputdlg(prompt,dlgtitle,dims,definput,opts);
    clinical_outcome = str2num(clinical_outcome{1});
% ask for sampling method    

    if isempty(interfering_mesh.Data.Source)
        samplingMethod = 'Check if fiber hits mesh';
        map = [];
        mesh = interfering_mesh.Data;
    else
        samplingMethod = 'undecided';
        map = interfering_mesh.Data.Source;
        mesh = interfering_mesh.Data;
    end

    %get method
    switch samplingMethod
        case 'Check if fiber hits mesh'
            %clear no more options to choose
        case 'undecided'
            options = {'Min value','Max value','Average Value','Sum','Check if fiber hits mesh'};
            [indx,tf] = listdlg('PromptString',{'Select method'},'ListString',options);
            samplingMethod = options{indx};
    end
    
    if strcmp(samplingMethod,'Sum')
        prompt = {sprintf('Please enter the threshold of points hit:')};
        dlgtitle = 'Set Threshold';
        definput = {num2str(min([0, 100]))}; % what should be max value?
        dims = [1 45];
        opts.Interpreter = 'tex';
        weight_thresh = inputdlg(prompt,dlgtitle,dims,definput,opts);
        weight_thresh = str2num(weight_thresh{1});
 %calculate interference for every loaded tract
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
            interfering_fibers.changeSetting('colorByWeight',true);
            Done;
            switch samplingMethod
                case {'Max value','Check if fiber hits mesh'}
                    fprintf("%f of %f fibers from %s hit\n",sum(interfering_fibers.Data.Weight), numel(interfering_fibers.Data.Vertices),interfering_fibers.Tag)
                    percentage_hit =  sum(interfering_fibers.Data.Weight)/numel(interfering_fibers.Data.Vertices);
                case 'Sum'
                    fprintf("%.2f of %.0f fibers from %s hit at at least %i points\n",sum(interfering_fibers.Data.Weight>weight_thresh), numel(interfering_fibers.Data.Vertices),interfering_fibers.Tag,weight_thresh)
                    percentage_hit =  sum(interfering_fibers.Data.Weight>weight_thresh)/numel(interfering_fibers.Data.Vertices);
            end
            hit_list(end +1,:) = [percentage_hit*100, clinical_outcome];
            fiber_list{end +1} = interfering_fibers.Tag;
        end
    end
    histo = figure('Name','Clinical Outcome vs Fibers hit');
    b = bar(hit_list);
    set(b, {'DisplayName'}, {'Fibers Hit', 'Clinical Outcome'}')
    ylim([0 100])
    legend()
    set(gca,'XTickLabel',fiber_list);
    ylabel('Percentage of clinical improvement and damaged fibers (%)');
end
 
    

