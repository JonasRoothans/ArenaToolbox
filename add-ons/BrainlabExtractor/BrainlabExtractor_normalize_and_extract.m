function [outputArg1,outputArg2] = BrainlabExtractor_normalize_and_extract(menu,eventdata,scene)
%BRAINLABEXTRACTOR_NORMALIZE_AND_EXTRACT Summary of this function goes here
%   Detailed explanation goes here

if nargin==0
    nativeTemplate = '/Volumes/silver/Studies/Hazem/GUIDEXT_Dataset/niis/01/T1.nii';
    BIfilename =  {    'VTA_right.nii', 'VTA_left.nii'};
    BIfoldername = '/Volumes/silver/Studies/Hazem/GUIDEXT_Dataset/niis/01';
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


diffdir = fullfile(BIfoldername,'temp');
%step 1
calculateDifferenceAndExportTo(diffdir)
%step 2
warpToMNI(diffdir)


    function calculateDifferenceAndExportTo(tempdir)
        
        vd_template_noreslice = VoxelData;
        vd_template_noreslice.loadnii(nativeTemplate,1);
        vd_template_noreslice.Voxels = uint16(vd_template_noreslice.Voxels);
        mkdir(tempdir);
        vd_template_noreslice.savenii_withSourceHeader(fullfile(tempdir,'master.nii'));
        
        
        for iBI = 1:numel(BIfilename)
            BIpath  = fullfile(BIfoldername,BIfilename{iBI});
            vd_BI_nr = VoxelData;
            vd_BI_nr.loadnii(BIpath,1);
            vd_BI_nr.Voxels = uint16(vd_BI_nr.Voxels);
            
            separated = vd_BI_nr - vd_template_noreslice;
            separated.SourceFile = vd_template_noreslice.SourceFile;
            separated.savenii_withSourceHeader(fullfile(tempdir,BIfilename{iBI}));
            
        end
        
        
        
        % %Repeat with reslicing
        %
        % vd_template = VoxelData(nativeTemplate);
        % tempfiles = A_getfiles(tempdir);
        %
        %
        % for iBI = 1:numel(tempfiles)
        %     BIpath = fullfile(tempfiles(iBI).folder,tempfiles(iBI).name);
        %     vd_BI = VoxelData(BIpath);
        %     vd_BI.warpto(vd_template);
        %
        %     vd_BI.getmesh(1).see(scene)
        % end
        %
        %
    end


    function tempnames = warpToMNI(diffdir)
        
        filenames = A_getfiles(diffdir);
        
        %templateDir = fullfile(handles.templateSpaces(handles.popup_template.Value).folder,handles.templateSpaces(handles.popup_template.Value).name);
        
        
        
        otherDir = {};
        for i = 1:numel(filenames)
            if strcmp(filenames(i).name,'master.nii')
                sourceDir = [fullfile(filenames(i).folder,filenames(i).name),',1'];
            else
                otherDir{end+1} = [fullfile(filenames(i).folder,filenames(i).name),',1'];
            end
        end
        otherDir = otherDir';
        
        
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
        matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.prefix = 'temp_';
        
        
        spm_jobman('run', matlabbatch);
        
        tempnames = {};
        for i = 1:numel(acpcFilenames)
            [folder,name] = fileparts(acpcFilenames{i});
            
            tempnames{i} = fullfile(folder,['temp_',name]);
        end
        
        
        
        
        
        
        
        
    end
end
