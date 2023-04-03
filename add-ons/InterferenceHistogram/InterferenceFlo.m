function InterferenceFlo(menuhandle,eventdata,scene)
%INTERFERENCE_RECIPEBASEDWORKFLOW Summary of this function goes here

%% load fibers
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
    
 
    %% get names and objects
    m_labels= {};
    m_list = {};
    m_scores = struct;
    f_labels = {};
    f_list= {};
    for iActor = 1:numel(scene.Actors)
        thisActor = scene.Actors(iActor);
        
        if  strcmp(class(thisActor.Data),'Mesh')
            m_labels{end+1} = strjoin(regexp(thisActor.Tag,'(\_|\.)','split'));
            m_list{end+1} = thisActor.Data;
            
           fnames = fieldnames(thisActor.Meta);
           for iFname = 1:numel(fnames)
                m_scores(length(m_list)).(fnames{iFname}) = thisActor.Meta.(fnames{iFname});
            end
        end
        if strcmp(class(thisActor.Data),'Fibers')
            f_labels{end+1} = strrep(strjoin(regexp(thisActor.Tag,'(\_|\.)','split')),' ','');
            f_list{end+1} = thisActor.Data;
        end
    end
    
    
    %% run analysis
    output = [];
    for iMesh = 1:length(m_list)
        m = m_list{iMesh};
        disp(m_labels{iMesh})
        for iFibers = 1:length(f_list)
        f = f_list{iFibers}    ;
        p =f.percentageHitByROI(m);
        output(iMesh,iFibers) = p;
        end
    end
    
    T = array2table(output, 'RowNames', m_labels, 'VariableNames', f_labels);
    T = addvars(T,struct2array(m_scores)','NewVariableNames', fieldnames(m_scores));

    writetable(T,fullfile(results_path,'fiberInterference.xlsx'),'WriteRowNames',true)
    
% Get the variable names in T
varNames = T.Properties.VariableNames;

% Create a formula string
formula = strcat(varNames{end}, ' ~ ', strjoin(varNames(1:end-1), ' + '));

% Fit a linear model
mdl = fitlm(T, formula)

Done;
    assignin('base','T',T)
    disp('all percentages are saved to workspace as ''T''')
    keyboard

end
