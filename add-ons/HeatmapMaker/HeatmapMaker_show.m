function [outputArg1,outputArg2] = HeatmapMaker_show(menu,eventdata,scene)
waitfor(msgbox('Find the recipe'))
[filename,foldername] = uigetfile('*.xlsx','Locate the recipe');
if filename==0
    return
end

%read the excel sheet
t = readtable(fullfile(foldername,filename));


%get colors
waitfor(msgbox('You will be asked to select colors. First for LOW values, then for HIGH values'));
low = uisetcolor();
high = uisetcolor();
medium = low+high;
medium(medium>1) =1;

%get score
labels = t.Properties.VariableNames(4:end);
if numel(labels)>1
    [indx] = listdlg('ListString',labels);
else
    indx = 1;
end
label = labels{indx};

minValue = min(t.(label));
maxValue = max(t.(label));
printwhendone = {};
if strcmp(t.Properties.VariableNames{1},'folderID')
for i = 1:height(t)
    filesInFolder = A_getfiles(fullfile(t.fullpath{i},'*.nii'));
    for j = 1:numel(filesInFolder)
    fname = fullfile(filesInFolder(j).folder,filesInFolder(j).name);
    vd = VoxelData(fname);
    
    
    %Mirror to the left.
    cog =  vd.getcog;
    if cog.x>1 && t.Move_or_keep_left(i)
        vd.mirror;
        printwhendone{end+1} = ['____mirrored: ',fname];
    else
        printwhendone{end+1} = ['not_mirrored: ',fname];
    end
    
                        
    actor = vd.getmesh(0.5).see(scene);
    
    %color
    Weight = t.(label)(i);
    WeightN = (Weight-minValue)/(maxValue-minValue);
    if isnan(WeightN) %no difference in scores in the heatmap
        WeightN = 0;
    end
        
    r = interp1([0,0.5,1],[low(1),medium(1),high(1)],WeightN);
    g = interp1([0,0.5,1],[low(2),medium(2),high(2)],WeightN);
    b = interp1([0,0.5,1],[low(3),medium(3),high(3)],WeightN);
    actor.changeSetting('colorFace',[r,g,b]);
    actor.Meta.label = Weight;
    actor.changeName([t.folderID{i},'_',filesInFolder(j).name])
    end
    
        


end
disp('---')
    cellfun(@disp,printwhendone)
    disp('---')
    disp('It is recommended to check the list above to see if mirroring was done correctly')
         



end
end

