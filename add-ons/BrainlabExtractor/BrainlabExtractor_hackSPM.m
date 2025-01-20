function BrainlabExtractor_hackSPM()
    % Specify the file name
    filename = 'spm_run_norm.m';
    
    fullfilename = which(filename);

    % Read the file into a cell array (each line is a cell)
    fileContent = {};
    fid = fopen(fullfilename, 'r'); % Open the file for reading
    if fid == -1
        error('Could not open file %s for reading', filename);
    end

    tline = fgetl(fid);
    while ischar(tline)
        fileContent{end+1, 1} = tline; % Append the line to the cell array
        tline = fgetl(fid);
    end
    fclose(fid); % Close the file after reading

    % Find and replace the desired line
    for i = 1:length(fileContent)
        if contains(fileContent{i}, 'preproc8.warp.write  = [0 1];')
            fileContent{i} = 'preproc8.warp.write  = [1 1];'; % Replace with the new line
            break; % Exit the loop as we only expect one occurrence
        end
    end

    % Write the modified content back to the file
    fid = fopen(fullfilename, 'w'); % Open the file for writing
    if fid == -1
        error('Could not open file %s for writing', filename);
    end

    for i = 1:length(fileContent)
        fprintf(fid, '%s\n', fileContent{i}); % Write each line to the file
    end
    fclose(fid); % Close the file after writing

    disp('Replacement complete!');