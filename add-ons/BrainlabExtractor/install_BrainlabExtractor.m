function install_BrainlabExtractor(menuhandle,eventdata,scene)

scene.addon_addmenuitem('BrainlabExtractor','Master: [none]',str2func('@BrainlabExtractor_AssignMaster'))
scene.addon_addmenuitem('BrainlabExtractor','burned-in: [none]',str2func('@BrainlabExtractor_AssignBI'))
scene.addon_addmenuitem('BrainlabExtractor','Electrodes by coordinates: [none]',str2func('@BrainlabExtractor_DefineElectrodes'))
scene.addon_addmenuitem('BrainlabExtractor','post-op CT: [none]',str2func('@BrainlabExtractor_CT'))
%------
sephere = scene.addon_addmenuitem('BrainlabExtractor','Segment only',str2func('@BrainlabExtractor_SegmentOnly'));
scene.addon_addmenuitem('BrainlabExtractor','Segment and normalize (SPM)',str2func('@BrainlabExtractor_SegmentNormalize'))


%add separator
m = handle(sephere);
m.Separator = 'on';


%change menu title
menuhandle.Text = menuhandle.Text(6:end);

%init userdata
menuhandle.UserData.master = [];
menuhandle.UserData.BIfilename = [];
menuhandle.UserData.BIfoldername = [];
menuhandle.UserData.CTfilename = [];
menuhandle.UserData.CTfoldername = [];
menuhandle.UserData.electrodes = nan;

disp('Docking complete')



end