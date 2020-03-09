function [actor] = A_loadsweetspot(scene)
%A_LOADSWEETSPOT Summary of this function goes here
%   Detailed explanation goes here

[filename,pathname] = uigetfile('*.swtspt');
swtspt = load(fullfile(pathname,filename),'-mat');

[indx] = listdlg('ListString',{swtspt.sweetspot.left.sweetspotArray.Title},...
    'PromptString',swtspt.sweetspot.description,...
    'ListSize',[250,150],...
    'SelectionMode','single');

vd = VoxelData(swtspt.sweetspot.left.sweetspotArray(indx).Data,swtspt.sweetspot.left.imref);



Tfake2mni = [-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1];
vd.imwarp(Tfake2mni);

mesh = vd.getmesh;
actor = mesh.see(scene);
actor.changeName(swtspt.sweetspot.left.sweetspotArray(indx).Title)

end

