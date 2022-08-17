function [outputArg1,outputArg2] = BrainlabExtractor_AssignMaster(menu,eventdata,scene)
%BRAINLABEXTRACTOT_ASSIGNMASTER Summary of this function goes here
%   Detailed explanation goes here

[filename,foldername] = uigetfile('*.nii','Locate the native template');
if filename==0
    return
end
    
%update the menu text
splt = strsplit(foldername(1:end-1),'/');

menuname = [splt{end},filesep,filename];
menu.Text = ['Master: ',menuname];


%save the filename
menu.Parent.UserData.master = fullfile(foldername,filename);
    

end

