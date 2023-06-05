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
segdir_coregdir=fullfile(BIfoldername,'segmented_and_coregistered')

mkdir(segdir)

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

%step 4 - visualisation
BrainlabExtractor_see(menu,eventdata,scene,warpeddir)


end
