function [outputArg1,outputArg2] = BrainlabExtractot_AssignMaster(menu,eventdata,scene)
%BRAINLABEXTRACTOT_ASSIGNMASTER Summary of this function goes here
%   Detailed explanation goes here

if isempty(menu.Parent.UserData.master)
    msgbox('Please select a master image first')
    return

end

%open ui

electrode(menu.Parent.UserData.electrodes)

menu.Parent.UserData.electrodes = evalin('base', 'electrodes');
if iscell(menu.Parent.UserData.electrodes )
    nElectrodes = sum(sum(not(cellfun(@isempty,menu.Parent.UserData.electrodes))))/6;
    menu.Text = ['Electrodes: ',num2str(nElectrodes)];
else
   menu.Text = 'Electrodes: [none]';
end








end

