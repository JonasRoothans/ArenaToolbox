function install_Noodles(menuhandle,eventdata,scene)

%create or reset config file
NoodlesConfig.fibers = {};
NoodlesConfig.fibersfolder = '';
NoodlesConfig.Cohort1 = {};
NoodlesConfig.Cohort2 = {};

%make menu
NoodlesConfig.handles.basic =  scene.addon_addmenuitem('Noodles','Basic pipeline');
NoodlesConfig.handles.fibers  = scene.addon_addmenuitem('Noodles','Fibers: None selected',str2func('@Noodles_selectFibers'),NoodlesConfig.handles.basic);
NoodlesConfig.handles.cohort1  = scene.addon_addmenuitem('Noodles','E-Fields Cohort 1: None selected',str2func('@Noodles_selectCohort1'),NoodlesConfig.handles.basic);
NoodlesConfig.handles.cohort2  = scene.addon_addmenuitem('Noodles','E-Fields Cohort 2: None selected',str2func('@Noodles_selectCohort2'),NoodlesConfig.handles.basic);
NoodlesConfig.handles.run  = scene.addon_addmenuitem('Noodles','Run',str2func('@Noodles_runbasic'),NoodlesConfig.handles.basic);

%disable run button until data is added
set(NoodlesConfig.handles.run ,'Enable','off')

%save config
NoodlesConfig.dir = fileparts(mfilename('fullpath'));
save(fullfile(NoodlesConfig.dir,'NoodlesConfig.mat'),'NoodlesConfig')

%finish
menuhandle.Text = menuhandle.Text(6:end);
disp('Docking complete')

end