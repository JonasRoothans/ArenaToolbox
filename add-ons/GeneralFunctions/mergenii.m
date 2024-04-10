
function mergenii(folder)
%to merge all nii in a folder to 4D image

content = A_getfiles(folder);

A = {};

for ii = 1:numel(content)
    
    if contains(content(ii).name,'.nii')
        
        
    A{end+1} = fullfile(content(ii).folder,content(ii).name);
    
    end
    
end

output = fullfile(folder,'merged.nii');
spm_file_merge(A,output)

end
    
    
    
        

    
    
