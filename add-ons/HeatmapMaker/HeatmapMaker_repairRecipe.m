function [outputArg1,outputArg2] = HeatmapMaker_repairRecipe(menu,eventdata,scene)
%HEATMAPMAKER_REPAIRRECIPE Summary of this function goes here

waitfor(msgbox('Find the recipe'))
[filename,foldername] = uigetfile('*.xlsx','Locate the recipe');
if filename==0
    return
end

%read the excel sheet
t = readtable(fullfile(foldername,filename));

%test 1: does the parent folder exist?
parentfolder = fileparts(t.fullpath{1});
if not(exist(parentfolder,'dir'))
    answer = questdlg('The parent folder cannot be found. Would you like to update the parent folder?','Missing path','Yes, I will select the correct folder.','No','Yes, I will select the correct folder.');
    switch answer
        case 'Yes, I will select the correct folder.'
            newparentfolder = uigetdir();
            
            for t_row = 1:height(t)
                [oldparent,folderfile,extension] = fileparts(t.fullpath{t_row});
                t.fullpath{t_row} = fullfile(newparentfolder,[folderfile,extension]);
            end
            
        case 'no'
            disp('whatever..')
    end
end


           
    
   writetable(t,fullfile(foldername,['updated_',filename]))
   Done;
    



                
                

end
