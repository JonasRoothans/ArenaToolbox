questdlg('You can only import .swtspt files!','Import',...
    'Import','Import');
[filename,pathname]=uigetfile('*.swtspt');
sweetspotFile=load(filename,'-mat');
% This followed part needs to be adjusted for the aimed target.
data=sweetspotFile.sweetspot;
data.dataleftcell=cellfun(@numel,data.dataleftcell);

datasample=VoxelData(); %general usable
% define your R values or you already have them in your data
datasample.R.PixelExtentInWorldX=data.spacing(1,1);
datasample.R.PixelExtentInWorldY=data.spacing(1,2);
datasample.R.PixelExtentInWorldZ=data.spacing(1,3);

datasample.Voxels=data.dataleftcell;

WorldLimitX=numel(data.dataleftcell(1:end,1,1))*data.spacing(1,1);
WorldLimitY=numel(data.dataleftcell(1,1:end,1))*data.spacing(1,2);
WorldLimitZ=numel(data.dataleftcell(1,1,1:end))*data.spacing(1,3);
WorldLimitX=[data.originMNIleft(1,1),data.originMNIleft(1,1)+WorldLimitX];
WorldLimitY=[data.originMNIleft(1,2),data.originMNIleft(1,2)+WorldLimitY];
WorldLimitZ=[data.originMNIleft(1,3),data.originMNIleft(1,3)+WorldLimitZ];

datasample.R=imref3d(data.dimensions,WorldLimitX,WorldLimitY,WorldLimitZ);
datasample.R=imref3d(data.dimensions,data.spacing(1,1),data.spacing(1,2),data.spacing(1,3));
[x,y,z] = datasample.R.worldToIntrinsic(0,0,0);
spacing = [datasample.R.PixelExtentInWorldX,datasample.R.PixelExtentInWorldY,datasample.R.PixelExtentInWorldZ];
origin = [x y z];
datatype = 16;%64;
nii = make_nii(double(permute(datasample.Voxels,[2 1 3])), spacing, origin, datatype);
filename=inputdlg('How do you want to name your file?','Filename');
save_nii(nii,[filename{1},'.nii']);




