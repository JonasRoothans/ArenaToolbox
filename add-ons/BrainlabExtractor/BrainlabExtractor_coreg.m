function [outputArg1,outputArg2] = BrainlabExtractor_coreg(master,inputfolder,outputfolder,Excluded)
%BRAINLABEXTRACTOR_WARP Summary of this function goes here
%   Detailed explanation goes here

        
        filenames = A_getfiles(inputfolder);
        
        otherDir = {};
        for i = 1:numel(filenames)
                movable_fn =  fullfile(filenames(i).folder,filenames(i).name);
                if contains(filenames(i).name,string(Excluded))
                    movefile(movable_fn ,fullfile(filenames(i).folder,['r_',filenames(i).name]))
                    continue
                end
                target =VoxelData(master);
                movable= VoxelData(movable_fn);
                movableCOG=movable.getcog;
                targetCOG = target.getcog;
                movecog = movableCOG - targetCOG;
                
                if any((movecog.x || movecog.y  || movecog.z) > 4)
                    movablecopy=movable.copy;
                    continue
                else
                    movablecopy = movable.copy;
                    
                    movablecopy.R.XWorldLimits = movablecopy.R.XWorldLimits-movecog.x;
                    movablecopy.R.YWorldLimits = movablecopy.R.YWorldLimits-movecog.y;
                    movablecopy.R.ZWorldLimits = movablecopy.R.ZWorldLimits-movecog.z;
                end
                movablecopy.savenii(fullfile(filenames(i).folder,filenames(i).name))
                movable_input=[fullfile(filenames(i).folder,filenames(i).name), ',1'];
                    

        
        
        %--- SPM SETTINGS        
        matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {master};
matlabbatch{1}.spm.spatial.coreg.estwrite.source = {movable_input};
matlabbatch{1}.spm.spatial.coreg.estwrite.other = {''};
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 4;
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.mask = 0;
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix = 'r_';

        
        
        spm_jobman('run', matlabbatch);

        %--- moving files
     
        end
     [~, ~] = mkdir(outputfolder);
     mni_files = A_getfiles(fullfile(inputfolder,'r_*'));
     for iFile = 1:numel(mni_files)
         movefile(fullfile(mni_files(iFile).folder,mni_files(iFile).name),...
             fullfile(outputfolder,mni_files(iFile).name));
     end
end

