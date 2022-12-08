function [outputArg1,outputArg2] = BrainlabExtractor_CT(menu,evenntdata,scene)
%BRAINLABEXTRACTOR_CT Summary of this function goes here
%   Detailed explanation goes here
[CTfile,CTfoldername] = uigetfile('*.nii','Get CT image','MultiSelect','off');
    if ~iscell(CTfile)
        if CTfile==0
            return
        end
    end
    
    if not(iscell(CTfile))
        CTfile = {CTfile};
    end
menu.Text = ['Burned-in: ',num2str(numel(CTfile))];


%save the filename
menu.Parent.UserData.CTfilename = CTfile;
menu.Parent.UserData.CTfoldername = CTfoldername;
end

