function [actor] = A_loadsweetspot(scene,swtsptfile)
%A_LOADSWEETSPOT Summary of this function goes here
%   Detailed explanation goes here

if nargin==1
    [filename,pathname] = uigetfile('*.swtspt');
    swtspt = load(fullfile(pathname,filename),'-mat');
    [~,label,~] = fileparts(filename);
else
    swtspt = load(swtsptfile,'-mat');
    [~,label,~] = fileparts(swtsptfile);
end

[indx] = listdlg('ListString',{swtspt.sweetspot.left.sweetspotArray.Title},...
    'PromptString',swtspt.sweetspot.description,...
    'ListSize',[250,150],...
    'SelectionMode','single');

vd = VoxelData(swtspt.sweetspot.left.sweetspotArray(indx).Data,swtspt.sweetspot.left.imref);



Tfake2mni = [-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1];
vd.imwarp(Tfake2mni);

mesh = vd.getmesh;
actor = mesh.see(scene);
actor.changeName([label,'__',swtspt.sweetspot.left.sweetspotArray(indx).Title])

end

