function BrainlabExtractor_updateNativeMenu(menu,eventdata,scene)

% 
mainPath = fileparts(mfilename('fullpath'));
warpPath = fullfile(mainPath,'Warp');  %for saving transformation matrix
all_warps = dir(fullfile(warpPath,'*.mat'));

menu_handle = get(scene.handles.menu.addons.BrainlabExtractor.external(11));
children = menu_handle.Children;

%remove all children
for iChild = 1:numel(children)
    thisChild = children(iChild);
    if strcmp(thisChild.Text,'+ new native link')
        continue
    end
    delete(thisChild)
end

%add all new children
for iWarp = 1:numel(all_warps)
    thisWarp = all_warps(iWarp);
    scene.addon_addmenuitem('BrainlabExtractor',thisWarp.name,str2func('@BrainlabExtractor_warpToNative'),scene.handles.menu.addons.BrainlabExtractor.external(11))
end



end

