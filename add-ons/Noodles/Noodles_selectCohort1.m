function [outputArg1,outputArg2] = Noodles_selectCohort1(menu,eventdata,scene)


load('NoodlesConfig.mat')
folder = uigetdir('Fibers');

files = A_getfiles(fullfile(folder,'*.nii'));

if numel(files)
    NoodlesConfig.Cohort1 = folder;
    [~, onlyFoldername ] =fileparts(folder);
    set(NoodlesConfig.handles.cohort1,'Text',['E-Fields Cohort 1: ',onlyFoldername,' (',num2str(numel(files)),')'],'Checked','on')
end


%save selection
save(fullfile(NoodlesConfig.dir,'NoodlesConfig.mat'),'NoodlesConfig')

Noodles_checkifready('Basic',scene)

end

