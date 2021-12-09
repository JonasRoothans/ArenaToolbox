function HeatmapMaker_sortPerPatient(menu,eventdata,scene)
%HEATMAPMAKER_SORTPERPATIENT Summary of this function goes here
%   Detailed explanation goes here

waitfor(msgbox('This tool will detect patient IDs and sort them into folders'))

path = uigetdir();
[parentfolder,lastfolder] = fileparts(path);
userinput = newid({'this text will be printed after the ID'},'How to save?',1,{lastfolder});

niifiles = A_getfiles(fullfile(path,'*.nii'));
for iFile = 1:length(niifiles)
    thisfile = niifiles(iFile);
    
    number = regexp(thisfile.name,'\d*','Match');
    
    numberstring  = sprintf( '%03d', str2double(number{1}));
    
    newfoldername = fullfile(parentfolder,[userinput{1},'_patientPerFolder'],numberstring);
    if ~exist(newfoldername,'dir')
        mkdir(newfoldername)
    end
    
    source = fullfile(thisfile.folder,thisfile.name);
    destination = fullfile(newfoldername,thisfile.name);
    copyfile(source,destination)

end



end

