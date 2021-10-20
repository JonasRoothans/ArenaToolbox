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
    if strcmp(roi,'all'); roi='**';end;
    folder_name = strcat('vtk_files_v1/',roi,'/*.vtk');
    vtk_files = dir(folder_name); %all vtk files
    loaded_actors = {scene.Actors.Tag};
    roi_names = {vtk_files.name};
    for ifile=1:length(vtk_files)
        filename = strcat(vtk_files(ifile).folder,'/',vtk_files(ifile).name);
        
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
        
        %Bar Plot of interference
        figure('Name',sprintf('Clinical Outcome vs Fibers hit for %s',mesh_name));
        b = bar(hit_list,'facecolor','flat');
        b.CData = cmap
        title(strcat("Improvement of clinical outcome: ",num2str(clinical_outcome(iMesh)),"%"))
        ax = gca
        set(ax,'XTickLabel',fiber_list);
        ax.FontSize =16
        xtickangle(40)
        ylim([0 105])
        ylabel('Percentage of fibers interfering with the lesion (%)');
        figure(scene_fig); % set current figure
        
        
    end
    %save as xls - 
    %xlswrite('filename.xlsx',yourmatrix)
    interference_results = cat(2,y,x);
    writetable(array2table(interference_results,'RowNames',mesh_list,'VariableNames',['improvement',fiber_list]),strcat(scene.Title,'_interference.xls'),'WriteRowNames',true');

    regression_results = regress(y,x);
    
    writetable(array2table(transpose(regression_results),'VariableNames',fiber_list),strcat(scene.Title,'_regression.xls'));

    for i=1:length(fiber_list)
    fprintf("%s :    %f.3\n",fiber_list{i},b(i))
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
            if not  (ismember(strcat(thisActor.Tag,'.vtk'),roi))
                continue
            end

            interfering_fibers = thisActor
            fibers_name = strjoin(regexp(interfering_fibers.Tag,'(\_|\.)','split'))
            
            scene.CallFromOutside.fiberMapInterference(map,samplingMethod,interfering_fibers)
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


