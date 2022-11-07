function  BrainlabExtractor_segment(master,BIfilename,BIfoldername,outputdir)
%BRAINLABEXTRACTOR_SEGMENT Summary of this function goes here
%   Detailed explanation goes here

%load the raw nifti (no reslicing tricks to avoid interpolation errors)
vd_template_noreslice = VoxelData;
vd_template_noreslice.loadnii(master,1); %"1" indicates no reslicing is applied.
vd_template_noreslice.Voxels = uint16(vd_template_noreslice.Voxels);
mkdir(tempdir);

%save it it in the right format
vd_template_noreslice.savenii_withSourceHeader(fullfile(outputdir,'master.nii'));



%load all burned-in images and subtract the master
for iBI = 1:numel(BIfilename)
    BIpath  = fullfile(BIfoldername,BIfilename{iBI});
    vd_BI_nr = VoxelData;
    vd_BI_nr.loadnii(BIpath,1);
    vd_BI_nr.Voxels = uint16(vd_BI_nr.Voxels);
    
    separated = vd_BI_nr - vd_template_noreslice;
    separated.SourceFile = vd_template_noreslice.SourceFile;
    separated.savenii_withSourceHeader(fullfile(outputdir,BIfilename{iBI}));
    
end



end

