function [outputArg1,outputArg2] = sweetspotstation_makerecipe(menu,eventdata,scene)

q_answer = questdlg('How is your data organized?','Arena','Subfolders per patient','All files in 1 folder','Subfolder');
if isempty(q_answer)
        disp('cancelled by user')
        return
end
parentfolder = uigetdir('Select the parentfolder');
subfolders = A_getsubfolders(parentfolder);
T = table;
switch q_answer
    case 'Subfolders per patient'
        disp(['Found ',num2str(length(subfolders)),' subfolders'])
        for i = 1:numel(subfolders)
            folder_ID{i,1} = subfolders(i).name;
            fullpath{i,1} = fullfile(subfolders(i).folder,subfolders(i).name);
            ENTER_SCORE_LABEL_AND_VALUES(i,1) = 0;
            Move_or_keep_left(i,1) = 1;
        end
        T.folderID = folder_ID;
        T.fullpath = fullpath;
        T.Move_or_keep_left = Move_or_keep_left;
        T.ENTER_SCORE_LABEL_AND_VALUES = ENTER_SCORE_LABEL_AND_VALUES;
        
    case 'All files in 1 folder'
        disp(['Found ',num2str(length(subfolders)),' subfolders'])
        counter = 0;
        for i = 1:numel(subfolders)
            niiFiles = A_getfiles(fullfile(subfolders(i).folder,subfolders(i).name,'*.nii'));
            for j = 1:numel(niiFiles)
                counter = counter+1;
                file_ID{counter} = niiFiles(j).name;
                fullpath{counter} = fullfile(subfolders(i).folder,subfolders(i).name,niiFiles(j).name);
                ENTER_SCORE_LABEL_AND_VALUES(counter) = 0;
                Move_or_keep_left(counter) = 1;
            end
            T.fileID = file_ID;
            T.fullpath = fullpath;
            T.Move_or_keep_left = Move_or_keep_left;
            T.ENTER_SCORE_LABEL_AND_VALUES = ENTER_SCORE_LABEL_AND_VALUES;
            
        end

        
        
end


writetable(T,fullfile(parentfolder,'recipe.xlsx'))
Done;
disp(['--> Recipe is saved in: ',parentfolder]);
disp('')
disp('How to proceed from here?')
disp('--------------------------')
disp('Open the recipe and add your values per file or folder.')
disp('Change the column name with your values. (do not use spaces)')
disp('You can have 3 columns with weights')

syscmd = ['open "', fullfile(parentfolder,'recipe.xlsx'), '" &'];
system(syscmd);


end

