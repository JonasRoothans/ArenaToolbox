function BrainlabExtractor_SegmentNormalize(menu,eventdata,scene)
%BRAINLABEXTRACTOR_NORMALIZE_AND_EXTRACT Summary of this function goes here
%   Detailed explanation goes here



nativeTemplate = menu.Parent.UserData.master;
BIfilename = menu.Parent.UserData.BIfilename;
BIfoldername = menu.Parent.UserData.BIfoldername;
%%% in the future , add a line here, if BIfoldername is empty use native template folder 
CTfilename = menu.Parent.UserData.CTfilename;
CTfoldername = menu.Parent.UserData.CTfoldername;
Excluded=BIfilename;
Excluded{end+1}='master';

%make dir for segmented files
segdir = fullfile(BIfoldername,'segmented');
warpeddir = fullfile(BIfoldername,'segmented_and_warped');
segdir_coregdir=fullfile(BIfoldername,'segmented_and_coregistered');

folderstructure = strsplit(BIfoldername,filesep);
folder_name = '';
while strcmp(folder_name,'')
    folder_name = folderstructure{end};
    folderstructure(end) = [];
end
    

mkdir(segdir)

if 0
    %step 1
    BrainlabExtractor_segment(nativeTemplate,BIfilename,BIfoldername,segdir);
    %step 1b?
    if iscell(menu.Parent.UserData.electrodes)
        BrainlabExtractor_makeLeadMarker(nativeTemplate,menu.Parent.UserData.electrodes,segdir)
    end

    %step 1c?
    if iscell(CTfilename)
        copyfile(fullfile(CTfoldername,CTfilename{1}),fullfile(segdir,'CT.nii'))
    end

    % %step 2
    BrainlabExtractor_coreg(nativeTemplate,segdir,segdir_coregdir, Excluded)

    %step 3a
    BrainlabExtractor_warp(nativeTemplate,segdir_coregdir,warpeddir)

    %step 3b
    BrainlabExtractor_cleanWarpArtifact(warpeddir)
end
%step 4 - visualisation
actors = BrainlabExtractor_see(menu,eventdata,scene,warpeddir);

%STEP 5 - extract leads from CT
for iActor = 1:numel(actors)
    if contains(actors(iActor).Tag,'CT')
        controlpanelright = scene.handles.panelright;
        controlpanelright.Value = iActor;
            %--- extract electrodes
        scene.CallFromOutside.extractElectrode(controlpanelright,[])
        newest_actors = scene.Actors(end-1:end);
        for newest_actor_i = 1:numel(newest_actors)
            new_actor = newest_actors(newest_actor_i);
            
                %--- find just created electrode
            if isa(new_actor.Data,'Electrode')
                new_actor.Data.Space = Space.MNI2009b;
                for iVTA_candidate = 1:numel(actors)
                    thisCandidate = actors(iVTA_candidate);
                    if contains(lower(thisCandidate.Tag),'vta') && contains(lower(thisCandidate.Tag),new_actor.Tag)
                        
                        %-- make new VTA and attach to Electrode
                        v = VTA();
                        v.Electrode= new_actor.Data;
                        v.ActorElectrode = new_actor;
                        v.Volume = thisCandidate.Data;
                        v.ActorVolume = thisCandidate;
                        v.Source = segdir_coregdir;
                        v.Space = Space.MNI2009b;
                        v.Tag = folder_name;
                        
                        new_actor.Data.VTA = v; 
                    end
                end
                        
                
                
                
            end
        end
        
    end
        

end
