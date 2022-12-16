function BrainlabExtractor_SegmentNormalize(menu,eventdata,scene)
%BRAINLABEXTRACTOR_NORMALIZE_AND_EXTRACT Summary of this function goes here
%   Detailed explanation goes here



nativeTemplate = menu.Parent.UserData.master;
BIfilename = menu.Parent.UserData.BIfilename;
BIfoldername = menu.Parent.UserData.BIfoldername;
CTfilename = menu.Parent.UserData.CTfilename;
CTfoldername = menu.Parent.UserData.CTfoldername;

%make dir for segmented files
segdir = fullfile(BIfoldername,'segmented');
warpeddir = fullfile(BIfoldername,'segmented_and_warped');
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

%step 2
BrainlabExtractor_warp(nativeTemplate,segdir,warpeddir)

%step 3 - visualisation
BrainlabExtractor_see(menu,eventdata,scene,warpeddir)


end
