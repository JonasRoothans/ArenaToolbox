function [LOO_regression,LOO_crossValidation] = A_LOO(niiFiles,scores, customFunction)

%This function will test if a correlation to a heatmap corresponds to a
%clinical assessment.

%- niiFiles: {file1.nii, file2.nii, file3.nii}
%- scores:   [    5     ,   -3    ,    1     ]
%- customFunction: output = @myFunction(niiFiles,scores)
%                     output: heatmap

clean_correlations = [];

for i = 1:numel(niiFiles)
    
    % extract 'the One' from the remaining
    one_niiFile = niiFiles{i};

    remaining_niiFiles = niiFiles;
    remaining_scores = scores;
    remaining_niiFiles(i) = [];
    remaining_scores(i) = [];
    
    %iteratively call the function to produce a heatmap:
    heatmap = feval(customFunction,remaining_niiFiles,remaining_scores);
    one_vd = VoxelData(one_niiFile);
    clean_correlations(i) = heatmap.corr(one_vd);
    
end
 
LOO_regression = fitlm(clean_correlations,scores);
LOO_crossValidation = LOORoutine.quickLOOCV(clean_correlations,scores);

    
end






