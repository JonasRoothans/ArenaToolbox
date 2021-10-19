function [outputArg1,outputArg2] = BrainlabExtractor_normalize_and_extract(menu,eventdata,scene);
%BRAINLABEXTRACTOR_NORMALIZE_AND_EXTRACT Summary of this function goes here
%   Detailed explanation goes here

if nargin==0
     nativeTemplate = '/Volumes/silver/Studies/Hazem/GUIDEXT_Dataset/niis/6/T1_MPRage_sag_1mm_iso_Elekta_KM.nii';
     BIfilename =  {    '20200610_Unnamed_024_BURNED-IN_NBM_Right_T1_MPRage_sag_1mm_iso_Elekta_KM.nii', '20200610_Unnamed_023_BURNED-IN_NBM_Left_T1_MPRage_sag_1mm_iso_Elekta_KM.nii'};
     BIfoldername = '/Volumes/silver/Studies/Hazem/GUIDEXT_Dataset/niis/6/';
else

waitfor(msgbox('Please select the NATIVE template image.'))
[filename,foldername] = uigetfile('*.nii','Locate the native templaet');
if filename==0
    return
end
nativeTemplate = fullfile(foldername,filename);

waitfor(msgbox('Now select all the burned-in images on the Template '))
[BIfilename,BIfoldername] = uigetfile('*.nii','Get Burned-in images','MultiSelect','on');
if filename==0
    return
end

end

vd_template = VoxelData(nativeTemplate);
vd_bi = VoxelData;

for iBI = 1:numel(BIfilename)
    BIpath = fullfile(BIfoldername,BIfilename{iBI});
    vd_BI = VoxelData(BIpath);
    vd_BI.warpto(vd_template);
    
    difference = vd_BI-vd_template;
    
    %if more than half of the voxels are more than "10" different..
    if sum(difference.Voxels(:)<10)/numel(difference.Voxels) > 0.5
        figure;plot(var(reshape(difference.Voxels,[],size(difference.Voxels,3))),1:size(difference.Voxels,3))
        difference.getslice.see
        
        var_template = var(reshape(vd_template.Voxels,[],size(vd_template.Voxels,3)));
        var_bi = var(reshape(vd_BI.Voxels,[],size(vd_BI.Voxels,3)));
        diff_var = var_bi-var_template;
        
    end
    
    
end


%template variance
figure;plot(var(reshape(vd_template.Voxels,[],size(vd_template.Voxels,3))),1:256)





end

