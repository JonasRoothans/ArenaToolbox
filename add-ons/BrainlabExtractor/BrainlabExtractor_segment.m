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
    if not(iscell(BIfilename))
        BIfilename= {BIfilename};
    end
    BIpath  = fullfile(BIfoldername,BIfilename{iBI});
    vd_BI_nr = VoxelData;
    vd_BI_nr.loadnii(BIpath,1);
    vd_BI_nr.Voxels = uint16(vd_BI_nr.Voxels);
    %vd_BI_nr.savenii_withSourceHeader(fullfile(outputdir,BIfilename{iBI}));
    
    vd_BI_nr = maybeReshapeInput1toMatchInput2(vd_BI_nr,vd_template_noreslice);
    
    separated = vd_BI_nr - vd_template_noreslice;
    separated.SourceFile = vd_template_noreslice.SourceFile;
    separated.savenii_withSourceHeader(fullfile(outputdir,['x_',BIfilename{iBI}]));
    
end



end

function a_corrected = maybeReshapeInput1toMatchInput2(a,b)
options_permute = [1,2,3;...
    1,3,2;...
    2,1,3;...
    2,3,1;...
    3,1,2;...
    3,2,1];

options_flip = [ 0 0 0;
    0 0 1;
    0 1 0
    0 1 1
    1 0 0
    1 0 1
    1 1 0
    1 1 1];


cost = [];
for iOption_p = 1:6
    try
       a_perm = permute(a.Voxels,options_permute(iOption_p,:));
       c = a_perm-b.Voxels;
       cost(iOption_p,1) = sum(c(:));
       for iOption_f = 2:8
           a_perm_flipped = a_perm;
           if options_flip(iOption_f,1)
               a_perm_flipped = flip(a_perm_flipped,1);
           end
           if options_flip(iOption_f,2)
               a_perm_flipped = flip(a_perm_flipped,2);
           end
           if options_flip(iOption_f,3)
               a_perm_flipped = flip(a_perm_flipped,3);
           end
           c = abs(a_perm_flipped-b.Voxels);
            cost(iOption_p,iOption_f) = sum(c(:));
          
       end
       
    catch
        cost(iOption_p,1:8) = inf;
    end
end
[indexP,indexF] = find(cost==min(cost(:)));
bestOptionP = options_permute(indexP,:);
bestOptionF = options_flip(indexF,:);
limits = [a.R.XWorldLimits;a.R.YWorldLimits;a.R.ZWorldLimits];
a_corrected_voxels = permute(a.Voxels,bestOptionP);
if bestOptionF(1)
    a_corrected_voxels = flip(a_corrected_voxels,1);
end
if bestOptionF(2)
    a_corrected_voxels = flip(a_corrected_voxels,2);
end
if bestOptionF(3)
    a_corrected_voxels = flip(a_corrected_voxels,3);
end


%color correction
intensity_correction = mode(a_corrected_voxels(:)./b.Voxels(:));
a_corrected_voxels= a_corrected_voxels/intensity_correction;

a_corrected = VoxelData(a_corrected_voxels,a.R);
% a_corrected.R.XWorldLimits = limits(bestOption(1),:);
% a_corrected.R.YWorldLimits = limits(bestOption(2),:);
% a_corrected.R.ZWorldLimits = limits(bestOption(3),:);
% a_corrected.R.ImageSize = a_corrected.R.ImageSize(bestOption);


end

