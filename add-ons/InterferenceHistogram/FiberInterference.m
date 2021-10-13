function FiberInterference(menuhandle,eventdata,scene)

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

% ask for sample method    

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
                case 'Sum'
                    for i=1:4
                    fprintf("%.2f of %.0f fibers from %s hit at at least %i points\n",sum(interfering_fibers.Data.Weight>i), numel(interfering_fibers.Data.Vertices),interfering_fibers.Tag,i)
                    end
            end
        end
    end
end
 
    

