function [samplingMethod,weight_thresh] = get_sampling_and_threshold()  % ask for sampling method    

    options = {'Min value','Max value','Average Value','Sum','Check if fiber hits mesh'};
    [indx,tf] = listdlg('PromptString',{'Select method'},'ListString',options);
    samplingMethod = options{indx};
    
    % set treshold for weights
    if strcmp(samplingMethod,'Sum')
        prompt = {sprintf('Please enter the threshold of points hit:')};
        dlgtitle = 'Set Threshold';
        definput = {num2str(min([0, 100]))}; 
        dims = [1 45];
        opts.Interpreter = 'tex';
        weight_thresh = inputdlg(prompt,dlgtitle,dims,definput,opts);
        weight_thresh = str2num(weight_thresh{1}); 
    else
        weight_thresh = 0
    end
end
  