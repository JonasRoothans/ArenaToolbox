function [outputArg1,outputArg2] = HeatmapMaker_UnpackFolders(menu,eventdata,scene)
%HEATMAPMAKER_REPAIRRECIPE Summary of this function goes here

waitfor(msgbox('Find the master folder'))
[mainfolder] = uigetdir();

subfolders = A_getsubfolders(mainfolder);

outputfoldername = fullfile(mainfolder,'AllFilesInOneFolder');
mkdir(outputfoldername)

for iFolder = 1:numel(subfolders)
    looppath = fullfile(mainfolder,subfolders(iFolder).name);
    allfiles = A_getfiles(looppath);
    for iFile = 1:numel(allfiles)
        copyfile(fullfile(looppath,allfiles(iFile).name),fullfile(outputfoldername,[subfolders(iFolder).name,allfiles(iFile).name]))
    end
end





    



                
                

end
