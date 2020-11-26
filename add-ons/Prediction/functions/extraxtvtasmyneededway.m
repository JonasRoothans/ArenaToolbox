questdlg('You can only import .dcm files!','Import',...
    'Import','Import');
[filename,pathname]=uigetfile('*.dcm');
thisprediction.Data_In=fullfile(pathname,filename);


waitfor(msgbox('Select your VTAPool'));
thisprediction.VTAPoolPath=uigetdir;
thisSession=Session;
thisSession.developerFlags.readable = 0; %this value needs to be cleared, that you can work on the data
thisSession.loadsession(thisprediction.Data_In);
[~,Rtype] = thisSession.listregisterables;
leadidcs = find(contains(Rtype,'Lead'));

lead=leadConnected();

for iLead =1: numel(leadidcs)
    % Everything which is needed for each single VTA
    thisLead = thisSession.getregisterable(leadidcs(1,iLead));
    for iStimplan = 1:numel(thisLead.stimPlan)
        lead.ExporttoVTApool(thisprediction,thisLead.stimPlan{iStimplan});
    end
end