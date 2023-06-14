function [outputArg1,outputArg2] = Batch_Brainlab(menu,eventdata,scene)

Notification=msgbox(['you will now be prompted to select the path of your data, subjects should be arranged in subfolders. T1 image should include the name (reference)',...
',all VTAs/ exported objects should include (BURNED-IN) in their respective names, postop CT should include (CT)']);
uiwait(Notification)
Selectedfolder=uigetdir()
% batch Brainlab extract
masterFolder=A_getsubfolders(Selectedfolder);

for ifolder=1:numel(masterFolder)
    BIfoldername=fullfile(masterFolder(ifolder).folder,masterFolder(ifolder).name) ;
    thefiles=A_getfiles(BIfoldername);
   BIfilename={};
    count=1;
    nativeTemplate='';
    
    for ifile=1:numel(thefiles)
        if contains(thefiles(ifile).name, 'reference', 'IgnoreCase',true)
            nativeTemplate=fullfile(BIfoldername, thefiles(ifile).name);
            continue
        elseif contains(thefiles(ifile).name, 'BURNED-IN', 'IgnoreCase',true)
            burnedin=fullfile(BIfoldername, thefiles(ifile).name);
            BIfilename{count}=thefiles(ifile).name;
            count=count+1;
            continue
        elseif contains(thefiles(ifile).name, 'CT', 'IgnoreCase',true)
            CTfilename=fullfile(BIfoldername, thefiles(ifile).name);
            
        end
    end
    Excluded=BIfilename;
    Excluded{end+1}=nativeTemplate;
    %make dir for segmented files
segdir = fullfile(BIfoldername,'segmented');
warpeddir = fullfile(BIfoldername,'segmented_and_warped');
segdir_coregdir=fullfile(BIfoldername,'segmented_and_coregistered');

mkdir(segdir)

%step 1
BrainlabExtractor_segment(nativeTemplate,BIfilename,BIfoldername,segdir);
%step 1b?


%step 1c?
if iscell(CTfilename)
    copyfile(fullfile(segdir,'CT.nii'))
end

% %step 2
BrainlabExtractor_coreg(nativeTemplate,segdir,segdir_coregdir, Excluded)

%step 3a
BrainlabExtractor_warp(nativeTemplate,segdir_coregdir,warpeddir)

%step 3b
BrainlabExtractor_cleanWarpArtifact(warpeddir)

%step 4 - visualisation
% BrainlabExtractor_see(menu,eventdata,scene,warpeddir)

end
Done;
end