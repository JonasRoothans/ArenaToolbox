function install_BrainlabExtractor(menuhandle,eventdata,scene)

scene.addon_addmenuitem('BrainlabExtractor','Master: [none]',str2func('@BrainlabExtractor_AssignMaster'))
scene.addon_addmenuitem('BrainlabExtractor','burned-in: [none]',str2func('@BrainlabExtractor_AssignBI'))
scene.addon_addmenuitem('BrainlabExtractor','Electrodes: [none]',str2func('@BrainlabExtractor_DefineElectrodes'))

menu = scene.addon_addmenuitem('BrainlabExtractor','Segment only',str2func('@BrainlabExtractor_SegmentOnly'));
m = handle(menu);
m.Separator = 'on';

scene.addon_addmenuitem('BrainlabExtractor','Segment and normalize (SPM)',str2func('@BrainlabExtractor_SegmentNormalize'))

%scene.addon_addmenuitem('BrainlabExtractor','Normalize and extract Burned-in images with SPM',str2func('@BrainlabExtractor_normalize_and_extract'))
menuhandle.Text = menuhandle.Text(6:end);

menuhandle.UserData.master = [];
menuhandle.UserData.BIfilename = [];
menuhandle.UserData.BIfoldername = [];
menuhandle.UserData.electrodes = nan;

disp('Docking complete')



end