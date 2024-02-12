function [outputArg1,outputArg2] = HeatmapMaker_convertleaddbsreco(menu,eventdata,scene)

waitfor(msgbox('Select the parent directory'))
folder = uigetdir();
searchAndConvert(folder)
Done;


end


function searchAndConvert(folderPath)
    % Check if the provided path is a folder
    if ~isfolder(folderPath)
        error('Input is not a valid folder path.');
    end
    
    % Get a list of all files and folders in the current folder
    contents = dir(folderPath);
    
    % Iterate through each item in the folder
    for i = 1:numel(contents)
        % Skip '.' and '..' directories
        if strcmp(contents(i).name, '.') || strcmp(contents(i).name, '..')
            continue;
        end
        
        % Construct the full path to the current item
        currentPath = fullfile(folderPath, contents(i).name);
        
        % If the current item is a folder, recursively call searchAndConvert()
        if isfolder(currentPath)
            searchAndConvert(currentPath);
        end
        
        % If the current item is a file and its name is 'reco.mat', send it to convertReco()
        if isfile(currentPath) && strcmp(contents(i).name, 'ea_reconstruction.mat')
            convertReco(currentPath);
        end
    end
end

function convertReco(currentPath)
    loaded = load(currentPath);
    electrodes = Electrode.convertReco(loaded.reco);
    outputfolder = fileparts(currentPath);
    for i = 1:numel(electrodes)
        e = electrodes(i);
        if e.C0.x > 0
            name = 'vat_right.electrode';
        else
            name = 'vat_left.electrode';
        end
        save(fullfile(outputfolder,name),'e')
    end

end