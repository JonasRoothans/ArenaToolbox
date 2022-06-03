    function [outputArg1,outputArg2] = HeatmapMaker_SuretuneSessions(menu,eventdata,scene)
    %HEATMAPMAKER_SURETUNESESSIONS Summary of this function goes here
    %   Detailed explanation goes here

    [files,folder] = uigetfile('*.dcm','MultiSelect','on');

    options = {'Stn','GPi'};
    listindx = listdlg('ListString',options, 'PromptString','Select the anatomy:');
    selectedAnatomy = options{listindx};


    options = {'together in 1 folder','per patient','per electrode','per electrode per patient'};
    listindx = listdlg('ListString',options, 'PromptString','Export the vtas');
    savePref = options{listindx};

    for iFile = 1:numel(files)
        thisFile = fullfile(folder,files{iFile});

        %suretune
        S = Session;
        S.loadsession(thisFile)


        %find the stimplans
        targetfolder = fullfile(folder,'VTAs');

        [name,type] = S.listregisterables;
        lead_indcs = find(contains(type,'Lead'));
        for iLead = lead_indcs
            thisLead = S.getregisterable(iLead);
            [T,reglinkdescription] = SuretuneTransformationTools.universalCallbackRoutine(thisLead, selectedAnatomy);

            for iStimplan = 1:numel(thisLead.stimPlan)
                            vd = VoxelData();
                            vd.importSuretuneDataset(thisLead.stimPlan{iStimplan}.vta.Medium);
                            vd.imwarp(T);

                            switch savePref
                                case 'together in 1 folder'
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
                            end
                            vd.saveToFolder(outputfolder,Tag)


            end
        end


        %move to MNI space

        %export as nifti in folder per patient

        %save the annotation
    end
    end



