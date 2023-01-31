function [actor] = A_loadheatmap(scene,heatmapfile)
%A_LOADSWEETSPOT Summary of this function goes here
%   Detailed explanation goes here

if nargin==1
    [filename,pathname] = uigetfile('*.swtspt;*.heatmap');
    if ismember(filename,'swtspt')
    hm=load(fullfile(pathname,filename),'-mat');
    else hm=Heatmap;
        hm.loadHeatmap(fullfile(pathname,filename));
    end
else
    try 
        hm=Heatmap;
        hm.loadHeatmap(heatmapfile);
    catch
    hm=load(heatmapfile,'-mat');
    end
    
end
try
label = hm.Tag;
catch
    warning('it looks you are runing an old heatmap, please enter required information')
    label=inputdlg('please enter label');
    try 
        hm.Description=hm.description
    catch
    hm.Description=inputdlg('please enter description');
    end
    warning(' buidling heatmap with missing properies')
    shell=Heatmap;
    props=properties(shell)
    for iprop=1:numel(props)
        if find(ismember(lower(props{iprop}),fieldnames(hm)))
            shell.(props{iprop})=hm.(lower(props{iprop}))
        end
    end
    hm=shell;
    hm.Tag=label{:};
end



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
    slice = vd.getslice;
    if any(contains(options,'Nmap'))
        amap = hm.Nmap.makeBinary(0.5); %at least 1
        slice.addAlphaMap(amap)
    end
    actor = slice.see(scene);
    actor.changeName([label,'__',thisProp])
end


end

