    function [outputArg1,outputArg2] = HeatmapMaker_SuretuneSessionsRecipe(menu,eventdata,scene)
    %HEATMAPMAKER_SURETUNESESSIONS Summary of this function goes here
    %   Detailed explanation goes here

    [files,folder] = uigetfile('*.dcm','MultiSelect','on');

    options = {'Stn','GPi'};
    listindx = listdlg('ListString',options, 'PromptString','Select the anatomy:');
    selectedAnatomy = options{listindx};


    options = {'together in 1 folder','per patient','per electrode','per electrode per patient'};
    listindx = listdlg('ListString',options, 'PromptString','Export the vtas');
    savePref = options{listindx};

    if ~iscell(files)
        files= {files};
    end
    for iFile = 1:numel(files)
        thisFile = fullfile(folder,files{iFile});

        %suretune
        S = Session;
        S.loadsession(thisFile)


        %find the stimplans
        targetfolder = fullfile(folder,'VTAs');

        [name,type] = S.listregisterables;
        lead_indcs = find(contains(type,'Lead'));
        tab = table;
        i = 0;
        for iLead = lead_indcs
            thisLead = S.getregisterable(iLead);
            [T,reglinkdescription] = SuretuneTransformationTools.universalCallbackRoutine(thisLead, selectedAnatomy);

            for iStimplan = 1:numel(thisLead.stimPlan)
                
                            vd = VoxelData();
                            vd.importSuretuneDataset(thisLead.stimPlan{iStimplan}.vta.Medium);
                            vd.imwarp(T);

                            switch savePref
                                case 'together in 1 folder'
                                    i = i+1;
                                    Tag = ['vta_',S.patient.name,'_',thisLead.label,'_',thisLead.stimPlan{iStimplan}.label];
                                    outputfolder = targetfolder;
                                case 'per patient'
                                    Tag = ['vta_',thisLead.label,'_',thisLead.stimPlan{iStimplan}.label];
                                    outputfolder = fullfile(targetfolder,S.patient.name);

                                case 'per electrode'
                                    Tag = ['vta_',thisLead.stimPlan{iStimplan}.label];
                                    outputfolder = fullfile(targetfolder,[S.patient.name,'_',thisLead.label]);
                                case 'per electrode per patient'
                                    Tag = ['vta_',thisLead.stimPlan{iStimplan}.label];
                                    outputfolder = fullfile(targetfolder,S.patient.name,thisLead.label);
                            end

                            if ~exist(outputfolder,'dir')
                                mkdir(outputfolder)
                                i = i+1;
                            end
                            if strcmp(savePref,'together in 1 folder')
                                file_ID{i,1} = Tag;
                            else
                                folder_ID{i,1} = [S.patient.name,'_',thisLead.label];
                            end
 
                            fullpath{i,1} = outputfolder;
                            ENTER_SCORE_LABEL_AND_VALUES(i,1) = 0;
                            Move_or_keep_left(i,1) = 1;
                            vd.saveToFolder(outputfolder,Tag)
                            
                            

            end
        end


    end
                            if ~strcmp(savePref,'together in 1 folder')
                                tab.folderID = folder_ID;
                            else
                                tab.fileID = file_ID;
                            end
                            tab.fullpath = fullpath;
                            tab.Move_or_keep_left = Move_or_keep_left;
                            tab.ENTER_SCORE_LABEL_AND_VALUES = ENTER_SCORE_LABEL_AND_VALUES;
                            
                            writetable(tab,fullfile(targetfolder,'recipe.xlsx'))

        
        
end
    



