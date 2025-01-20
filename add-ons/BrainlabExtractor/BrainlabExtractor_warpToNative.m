function [outputArg1,outputArg2] = BrainlabExtractor_warpToNative(menu,eventdata,scene)

%load T
mainPath = fileparts(mfilename('fullpath'));
warpPath = fullfile(mainPath,'Warp');  
load(fullfile(warpPath,menu.Text));

%get selected actors
currentActors = ArenaScene.getSelectedActors(scene);
for iActor = 1:numel(currentActors)
    thisActor = currentActors(iActor);
    copy = thisActor.duplicate(scene);
    copy.transform(scene,'T',T)
    copy.changeName([copy.Tag,' ',menu.Text])
end
    




end

