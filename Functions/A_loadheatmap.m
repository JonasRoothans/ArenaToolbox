function [actor] = A_loadheatmap(scene,heatmapfile)
%A_LOADSWEETSPOT Summary of this function goes here
%   Detailed explanation goes here

if nargin==1
    [filename,pathname] = uigetfile('*.swtspt');
    load(fullfile(pathname,filename),'-mat');
else
    load(heatmapfile,'-mat');
end

label = hm.Tag;

props = properties(hm);
options = {};
for iProp = 1:numel(props)
    if isa(hm.(props{iProp}),'VoxelData')
        options{end+1} =props{iProp};
    end
end

[indx] = listdlg('ListString',options,...
    'PromptString',hm.Description,...
    'ListSize',[250,150]);

for i = indx
    thisProp = options{i};
    vd = hm.(thisProp);
    actor = vd.getslice.see(scene);
    actor.changeName([label,'__',thisProp])
end


end

