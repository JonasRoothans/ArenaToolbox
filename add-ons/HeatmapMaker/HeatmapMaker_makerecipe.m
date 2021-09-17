function [outputArg1,outputArg2] = sweetspotstation_makerecipe(menu,eventdata,scene)

q_answer = questdlg('How is your data organized?','Arena','Subfolders','File','Subfolder');
parentfolder = uigetdir('Select the parentfolder');
subfolders = A_getsubfolders(parentfolder);
T = table;
switch q_answer
    case 'Subfolders'
        disp(['Found ',num2str(length(subfolders)),' subfolders'])
        for i = 1:numel(subfolders)
            folder_ID{i} = subfolders(i).name;
            fullpath{i} = fullfile(subfolders(i).folder,subfolders(i).name);
            ENTER_SCORE_LABEL_AND_VALUES(i) = 0;
        end
        T.folderID = folder_ID;
        T.fullpath = fullpath;
        T.ENTER_SCORE_LABEL_AND_VALUES = ENTER_SCORE_LABEL_AND_VALUES;
        
    case 'File'
        disp(['Found ',num2str(length(subfolders)),' subfolders'])
        counter = 0;
        for i = 1:numel(subfolders)
            niiFiles = A_getfiles(fullfile(subfolders(i).folder,subfolders(i).name,'*.nii'));
            for j = 1:numel(niiFiles)
                counter = counter+1;
                file_ID{counter} = niiFiles(j).name;
                fullpath{counter} = fullfile(subfolders(i).folder,subfolders(i).name,niiFiles(j).name);
                ENTER_SCORE_LABEL_AND_VALUES(counter) = 0;
            end
            T.file_ID = file_ID;
            T.fullpath = fullpath;
            T.ENTER_SCORE_LABEL_AND_VALUES = ENTER_SCORE_LABEL_AND_VALUES;
        end
end


writetable(T,fullfile(parentfolder,'recipe.xlsx'))
Done;
disp(['--> Recipe is saved in: ',parentfolder]);

end

