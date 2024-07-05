function  openheatmap(filename)
disp(['loading: ',filename])
loaded = load(filename,'-mat');



fnames = fieldnames(loaded);
if contains(fnames,'hm')
    loaded.hm.Tag = strrep(loaded.hm.Tag,'.','');
    basename = ['hm_',loaded.hm.Tag];
    assignin('base',['hm_',loaded.hm.Tag],loaded.hm)
    disp(['Heatmap ''',loaded.hm.Tag,''' is saved to the workspace as ''',basename,''''])
elseif contains(fnames,'heatmap')
    loaded.heatmap.Tag = strrep(loaded.heatmap.Tag,'.','');
    basename = ['hm_',loaded.heatmap.Tag];
    assignin('base',basename,loaded.heatmap)
    disp(['Heatmap ''',loaded.heatmap.Tag,''' is saved to the workspace as ''',basename,''''])
end


end

