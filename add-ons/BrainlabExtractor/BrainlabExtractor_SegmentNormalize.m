function BrainlabExtractor_SegmentNormalize(menu,eventdata,scene)
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
%step 1b?
if iscell(menu.Parent.UserData.electrodes)
    BrainlabExtractor_makeLeadMarker(nativeTemplate,menu.Parent.UserData.electrodes,diffdir)
end
%step 2
BrainlabExtractor_warp(nativeTemplate,diffdir)
%step 3
importWarped(diffdir)
importLead(diffdir)


    function importWarped(diffdir)
        files = A_getfiles(fullfile(diffdir,'mni_*.nii'));
        for iFile = 1:numel(files)
            thisFile = files(iFile);
            if contains(thisFile.name,'lead')
                continue
            end
            thisPath = fullfile(diffdir,thisFile.name);
            vd = VoxelData(thisPath);
            percent0 = total(round(vd)<=0)/numvox(vd)*100;
            if percent0>70
               vd.round()
               vd.Voxels(isnan(vd.Voxels)) =0;
               vd.Voxels(vd.Voxels<0) = 0;
               vd.getmesh(100).see(scene)
            else
                vd.getslice.see(scene);
            end
            
        end
    end

    function importLead(diffdir)
        files = A_getfiles(fullfile(diffdir,'mni_lead*.nii'));
        for iLead = 1:numel(files)/2
            
            tip = VoxelData(['mni_lead',num2str(iLead),'_tip.nii']).getmesh(100).getCOG;
            top = VoxelData(['mni_lead',num2str(iLead),'_top.nii']).getmesh(100).getCOG;
            direction = top-tip;
            e = Electrode(tip,direction.unit);
            e.see(scene)
        end
    end


end
