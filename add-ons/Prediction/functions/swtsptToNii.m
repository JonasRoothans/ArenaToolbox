questdlg('You can only import .swtspt files!','Import',...
    'Import','Import');
[filename,pathname]=uigetfile('*.swtspt');
sweetspotFile=load(filename,'-mat');
% This followed part needs to be adjusted for the aimed target.
data=sweetspotFile.sweetspot;
data.dataleftcell=cellfun(@numel,data.dataleftcell);

datasample=VoxelData(); %general usable
% define your R values or you already have them in your data

datasample.Voxels=data.dataleftcell;

datasample.R = imref3d(data.dimensions([2 1 3]),data.spacing(1,1),data.spacing(1,2),data.spacing(1,3));
datasample.R.XWorldLimits = datasample.R.XWorldLimits+data.originMNIleft(1,1)-data.spacing(1,1);
datasample.R.YWorldLimits = datasample.R.YWorldLimits+data.originMNIleft(1,2)-data.spacing(1,2);
datasample.R.ZWorldLimits = datasample.R.ZWorldLimits+data.originMNIleft(1,3)-data.spacing(1,3);

[x,y,z] = datasample.R.worldToIntrinsic(0,0,0);
spacing = [datasample.R.PixelExtentInWorldX,datasample.R.PixelExtentInWorldY,datasample.R.PixelExtentInWorldZ];
origin = [x y z];
datatype = 16;%64;
nii = make_nii(double(permute(datasample.Voxels,[2 1 3])), spacing, origin, datatype);
filename=inputdlg('How do you want to name your file?','Filename');
save_nii(nii,[filename{1},'.nii']);




