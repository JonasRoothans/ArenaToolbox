function [outputArg1,outputArg2] = Noodles_selectCohort2(menu,eventdata,scene)


load('NoodlesConfig.mat')
folder = uigetdir('Fibers');

files = A_getfiles(fullfile(folder,'*.nii'));

if numel(files)
    NoodlesConfig.Cohort2 = folder;
    [~, onlyFoldername ] =fileparts(folder);
    set(NoodlesConfig.handles.cohort2,'Text',['E-Fields Cohort 2: ',onlyFoldername,' (',num2str(numel(files)),')'],'Checked','on')
end


%save selection
save(fullfile(NoodlesConfig.dir,'NoodlesConfig.mat'),'NoodlesConfig')

Noodles_checkifready('Basic',scene)



end

