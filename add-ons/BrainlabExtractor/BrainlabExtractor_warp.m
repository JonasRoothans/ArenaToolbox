function [outputArg1,outputArg2] = BrainlabExtractor_warp(master,folder,outputfolder)
%BRAINLABEXTRACTOR_WARP Summary of this function goes here
%   Detailed explanation goes here

        
        
        sourceDir = [master,',1'];
        
        if isempty(folder)
            otherDir = {sourceDir};
            folder = fileparts(master);
        else
            filenames = A_getfiles(folder);
            otherDir = {};
            for i = 1:numel(filenames)
                    otherDir{end+1} = [fullfile(filenames(i).folder,filenames(i).name),',1'];

            end
            otherDir = otherDir';
            
        end
        
        
        
        p = fileparts(mfilename('fullpath'));
        try
            load(fullfile(p,'lead_MNI_dir.mat'));
        catch
            wf = msgbox('Looks like this is the first time you are using this tool, please find the lead_dbs template folder');
            waitfor(wf);
            lead_MNI_dir = uigetdir();
            save(fullfile(p,'lead_MNI_dir.mat'),'lead_MNI_dir')
        end
        
        
        %--- SPM SETTINGS
        matlabbatch{1}.spm.spatial.normalise.estwrite.subj.vol ={sourceDir};
        matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = otherDir;
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.biasreg = 0.0001;
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.biasfwhm = 60;
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.tpm = {fullfile(lead_MNI_dir,'TPM_Lorio_Draganski.nii')};
        %matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.tpm = {fullfile(SPMdir,'Tpm/TPM.nii')};
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.affreg = 'mni';
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.reg = [0 0.001 0.5 0.05 0.2];
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.fwhm = 0;
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.samp = 3;
        matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.bb = [-78 -112 -70 78 76 85];
        matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.vox = [1 1 1];
        matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.interp = 4;
        matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.prefix = 'mni_';
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.write = [1 1]; % EXPORT FORWARD (1st) AND INVERSE (2nd) DEFORMATION FIELDS
        
        
        spm_jobman('run', matlabbatch);

        %--- moving files
     mkdir(outputfolder);
     mni_files = A_getfiles(fullfile(folder,'mni*'));
     for iFile = 1:numel(mni_files)
         movefile(fullfile(mni_files(iFile).folder,mni_files(iFile).name),...
             fullfile(outputfolder,mni_files(iFile).name));
     end
     mni_files = A_getfiles(fullfile(folder,'y_*'));
     for iFile = 1:numel(mni_files)
         movefile(fullfile(mni_files(iFile).folder,mni_files(iFile).name),...
             fullfile(outputfolder,mni_files(iFile).name));
     end

end

