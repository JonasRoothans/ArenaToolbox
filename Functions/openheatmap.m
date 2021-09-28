function  openheatmap(filename)
disp(['loading: ',filename])
loaded = load(filename,'-mat');

assignin('base','hm',loaded.hm)
disp(['Heatmap ''',loaded.hm.Tag,''' is saved to the workspace as ''hm'''])

end

