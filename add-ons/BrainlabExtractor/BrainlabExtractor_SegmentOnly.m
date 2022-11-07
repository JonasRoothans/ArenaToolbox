function BrainlabExtractor_SegmentOnly(menu,eventdata,scene)
%BRAINLABEXTRACTOR_NORMALIZE_AND_EXTRACT Summary of this function goes here
%   Detailed explanation goes here

nativeTemplate = menu.Parent.UserData.master;
BIfilename = menu.Parent.UserData.BIfilename;
BIfoldername = menu.Parent.UserData.BIfoldername;

%make directory for segmented files
segdir = fullfile(BIfoldername,'segmented');
mkdir(segdir)

%execute
BrainlabExtractor_segment(nativeTemplate,BIfilename,BIfoldername,segdir);

end
