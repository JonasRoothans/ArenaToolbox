%this script was made with Benedikt and Regina and Jonas via skype.
% it exports VTAs in MNI space based on the atlas link.
% input should be a suretune session (or multiple)


disp('Make sure to set target to your desired target!')
target = 'stn'; %or gpi
%% Design summary


% 1. Selecting input files and output folder
% 2. Loop over selected sessions
%    a.  Loop over stimplans
% 3. save each vta as a nifti


%% 1. Selecting input files and output folder
%Select Files
[filename,pathname] = uigetfile({'*.dcm'},'Select SureTune Sessions','MultiSelect','on');
%select Folder to save to
savefolder = uigetdir('C:\','Select Folder to save to');

%check if anything selected
if numel(filename)==0       %I think the uigetfile doesn't allow you to get back without taking anything... 
    disp('Nothing was selected.')
    return
end

if isa(filename,'char')     %why check if character when every input is given as char?
    filename = {filename};
end
    



%% 2. Loop over selected sessions
%loop all files and check, if empty

for iFile = 1:numel(filename)
    [folder,name,ext] = fileparts(filename{iFile});
            %display progress
                home 
                formatSpec = '\n--------------------\n File %d/%d\n\n';
                fprintf(formatSpec, iFile, numel(filename))
    
%load from suretune
  %loadSession   
     if ~exist('Session','class')
            loadSDK;        %behind this there is no function like it should be
     end
     

    thisSession = Session; %    thisSession.developerFlags.readable = 0;  
    thisSession.loadsession(fullfile(pathname,name));
    
    stimPlanList = thisSession.therapyPlanStorage;
%%    a.  Loop over stimplans
    for iStimPlan = 1:numel(stimPlanList)
        thisStimPlan = stimPlanList{iStimPlan};
        
        atlas = findTheMatchingAtlas(thisStimPlan,thisSession,target); % =reglink in A_loadsuretune %never put the function you need later on in the same .m file...?
        
        %get Transformation from electrode to selected atlas
        T_vta_to_atlas = thisSession.gettransformfromto(thisStimPlan.lead,atlas);
        [T_atlas_to_mni,hemisphere]  = findTtoMNI(thisStimPlan, target); %this works if you don't put the one area of left to right, then you can use this; but for the prediction there is a big problem
        T = round(T_vta_to_atlas*T_atlas_to_mni,6);
        
        %get and warp the VTA
        vd = VoxelData();
        vd.importSuretuneDataset(thisStimPlan.vta.Medium);
        vd = vd.imwarp(T);
        
        %define output
        patientname = thisSession.patient.name;
        stimplanname = thisStimPlan.label;
        outputfilename = [patientname,'_',hemisphere,'_',stimplanname,'.nii'];
        vd.savenii(fullfile(savefolder,outputfilename))
                
        %Reslicing could be done here.But isn't.
        
    end
   
    clear thisSession thisStimPlan vd
end

    
    
    
function atlas = findTheMatchingAtlas(thisStimplan,thisSession,target)
        [~,types] = thisSession.listregisterables;
        atlas_indices = find(contains(types,'Atlas'));
        names = {};
        regs = {};
        atlas = [];
        for i = atlas_indices
            % is target matching?
            thisAtlas = thisSession.getregisterable(i);
            
            if not(strcmp(lower(thisAtlas.group),lower(target))) %rechecking with predictFuture
                continue
            end
            
            % is hemisphere matching?
            if not(contains(lower(thisStimplan.lead.label),...
                           lower(thisAtlas.hemisphere)))
                continue
            end
            
            atlas = thisAtlas;
            break               %this is a dangerous writing style, when something is wrong it could cause distortions  
        end
        if isempty(atlas)
            error(['No atlas was found for:', lower(thisStimplan.lead.label),' and ',lower(target)])
        end
end

    
    
function [T_atlas_to_mni,hemisphere]  = findTtoMNI(thisStimPlan, target)
        
            hemispheres = {'left','right'};
                for iHemi = 1:2
                    thisHemi = hemispheres{iHemi};
                    if not(contains(lower(thisStimPlan.lead.label),...
                            lower(thisHemi)))
                        continue
                    end
                    hemisphere = thisHemi;
                    break
                end

             T = load('Tapproved.mat'); %Tapproved.mat is for transform everything to legacy or back
                atlasname = [lower(hemisphere),lower(target),'2mni'];
                Tatlas2fake = T.(atlasname);            %sweetspotspace is the same like legacyspace?
                Tfake2mni = [-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1];
                T_atlas_to_mni = Tatlas2fake*Tfake2mni;
end
    
    
    
    
    
    