function BrainlabExtractor_SegmentOnly(menu,eventdata,scene)
%BRAINLABEXTRACTOR_NORMALIZE_AND_EXTRACT Summary of this function goes here
%   Detailed explanation goes here

if nargin==0
    nativeTemplate = '/Volumes/silver/Studies/Hazem/GUIDEXT_Dataset/niis/01/T1.nii';
    BIfilename =  {    'VTA_right.nii', 'VTA_left.nii'};
    BIfoldername = '/Volumes/silver/Studies/Hazem/GUIDEXT_Dataset/niis/01';
else
    
    nativeTemplate = menu.Parent.UserData.master;
    
    BIfilename = menu.Parent.UserData.BIfilename;
    BIfoldername = menu.Parent.UserData.BIfoldername;
end


diffdir = fullfile(BIfoldername,'segmented');
mkdir(diffdir)
%step 1
BrainlabExtractor_segment(nativeTemplate,BIfilename,BIfoldername,diffdir);


    


end
