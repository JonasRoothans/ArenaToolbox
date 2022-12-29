function [outputArg1,outputArg2] = BrainlabExtractor_warp(master,inputfolder,outputfolder)
%BRAINLABEXTRACTOR_WARP Summary of this function goes here
%   Detailed explanation goes here

        
        filenames = A_getfiles(inputfolder);
        
        otherDir = {};
        for i = 1:numel(filenames)
                slave =  [fullfile(filenames(i).folder,filenames(i).name),',1'];

        
        
        %--- SPM SETTINGS        
        matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {master};
matlabbatch{1}.spm.spatial.coreg.estwrite.source = {slave};
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
     [~, ~] = mkdir(outputfolder);
     mni_files = A_getfiles(fullfile(inputfolder,'r_*'));
     for iFile = 1:numel(mni_files)
         movefile(fullfile(mni_files(iFile).folder,mni_files(iFile).name),...
             fullfile(outputfolder,mni_files(iFile).name));
     end
    end
end

