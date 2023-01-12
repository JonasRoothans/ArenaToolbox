function  BrainlabExtractor_cleanWarpArtifact(warpeddir)


files = A_getfiles(fullfile(warpeddir,'*.nii'));
for iFile = 1:numel(files)
    vd = VoxelData(fullfile(files(iFile).folder,files(iFile).name));
    if mean(vd.Voxels(:)==0)>0.99
        if any(vd.Voxels(:)<0)
            restored = vd.makeBinary(100);
            restored.Voxels = restored.Voxels*1000;
            restored.savenii(fullfile(files(iFile).folder,files(iFile).name))
        end
    end
    
end

end

