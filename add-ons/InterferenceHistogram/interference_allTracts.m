function [hit_list,fiber_list,cmap] = interference_allTracts(interfering_mesh,scene,samplingMethod,weight_thresh,roi)
    scene_fig = gcf;

    if isempty(interfering_mesh.Data.Source)
        samplingMethod = 'Check if fiber hits mesh';
        map = [];
    else
        map = interfering_mesh.Data.Source;
    end

    mesh = interfering_mesh.Data;

    hit_list = [];
    fiber_list = {};
    cmap = [];
    for iActor = 1:numel(scene.Actors)
    thisActor = scene.Actors(iActor);
        if  strcmp(class(thisActor.Data),'Fibers')
            if nargin>4 && not  (ismember(strcat(thisActor.Tag,'.vtk'),roi))
                continue
            end

            interfering_fibers = thisActor
            fibers_name = strjoin(regexp(interfering_fibers.Tag,'(\_|\.)','split'))
            
            scene.CallFromOutside.fiberMapInterference(map,mesh,samplingMethod,interfering_fibers)
            figure(scene_fig); 
            switch samplingMethod
                case {'Max value','Check if fiber hits mesh'}
                    fprintf("%f of %f fibers from %s hit\n",sum(interfering_fibers.Data.Weight), numel(interfering_fibers.Data.Vertices),fibers_name)
                    percentage_hit =  sum(interfering_fibers.Data.Weight)/numel(interfering_fibers.Data.Vertices);
                case 'Sum'
                    fprintf("%.2f of %.0f fibers from %s hit at at least %i points\n",sum(interfering_fibers.Data.Weight>weight_thresh), numel(interfering_fibers.Data.Vertices),fibers_name,weight_thresh)
                    percentage_hit =  sum(interfering_fibers.Data.Weight>weight_thresh)/numel(interfering_fibers.Data.Vertices);
            end
            hit_list(end +1,:) = [percentage_hit*100];
            fiber_list{end +1} = fibers_name(find(~isspace(fibers_name)));
            cmap(end+1,:) = interfering_fibers.Visualisation.settings.colorFace2;
        end
    end

end