function [outputArg1,outputArg2] = BrainlabExtractor_AssignBI(menu,eventdata,scene)
%BRAINLABEXTRACTOR_DEFINEBI Summary of this function goes here
%   Detailed explanation goes here

%BI stands for Burned-In

[BIfilename,BIfoldername] = uigetfile('*.nii','Get Burned-in images','MultiSelect','on');
    if ~iscell(BIfilename)
        if BIfile==0
            return
        end
    end
    
%update the menu text
menu.Text = ['Burned-in: ',num2str(numel(BIfilename))];


%save the filename
menu.Parent.UserData.BIfilename = BIfilename;
menu.Parent.UserData.BIfoldername = BIfoldername;
    


end

