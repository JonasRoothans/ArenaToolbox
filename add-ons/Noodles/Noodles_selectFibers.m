function [outputArg1,outputArg2] = Noodles_selectFibers(menu,eventdata,scene)


load('NoodlesConfig.mat')
uiwait(msgbox('Please select your fibers. Tip: Add them to the ''Fibers'' folder in Arena Noodles for a quick workflow'))
[files,folder] = uigetfile('*','MultiSelect','on','defname','Fibers');

if numel(files)
    NoodlesConfig.fibers = files;
    NoodlesConfig.fibersfolder = folder;
    set(NoodlesConfig.handles.fibers,'Text',['Fibers: ',num2str(numel(files)),' selected'],'Checked','on')
end


%save selection
save(fullfile(NoodlesConfig.dir,'NoodlesConfig.mat'),'NoodlesConfig')

Noodles_checkifready('Basic',scene)


end

