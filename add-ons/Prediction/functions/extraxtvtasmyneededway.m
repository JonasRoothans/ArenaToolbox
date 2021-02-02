questdlg('You can only import .dcm files!','Import',...
    'Import','Import');
[filename,pathname]=uigetfile('*.dcm');

thisprediction.Data_In=fullfile(pathname,filename);


% waitfor(msgbox('Select your VTAPool'));
%thisprediction.VTAPoolPath=uigetdir;
thisprediction.VTAPoolPath='/Users/w/Documents/Praktikum/VTAPool27.01.try';
thisSession=Session;
thisSession.developerFlags.readable = 0; %this value needs to be cleared, that you can work on the data
thisSession.loadsession(thisprediction.Data_In);
[~,Rtype] = thisSession.listregisterables;
leadidcs = find(contains(Rtype,'Lead'));


for iLead =1: numel(leadidcs)
    % Everything which is needed for each single VTA
    thisLead = thisSession.getregisterable(leadidcs(1,iLead));
    thisStimplan=thisLead.stimPlan;
    for iStimplan = 1:numel(thisLead.stimPlan)
            type = thisStimplan{iStimplan}.lead.leadType;
            amp = num2str(round(thisStimplan{iStimplan}.stimulationValue,1));
            voltagecontrolled = thisStimplan{iStimplan}.voltageBasedStimulation;
            pw = num2str(thisStimplan{iStimplan}.pulseWidth);
            cathode = ['c',thisStimplan{iStimplan}.activeRings];
            anode = ['a',thisStimplan{iStimplan}.contactsGrounded];
            name = [type,amp,voltagecontrolled,pw,cathode,anode,'.mat'];
            
            %Rvta: dim, spacing
            Rvta = imref3d(thisStimplan{1}.vta.Medium.volumeInfo.dimensions,...
                thisStimplan{1}.vta.Medium.volumeInfo.spacing(1),...
                thisStimplan{1}.vta.Medium.volumeInfo.spacing(2),...
                thisStimplan{1}.vta.Medium.volumeInfo.spacing(3));
            %Rvta: origin
            Rvta.XWorldLimits = Rvta.XWorldLimits+thisStimplan{1}.vta.Medium.volumeInfo.origin(1);
            Rvta.YWorldLimits = Rvta.YWorldLimits+thisStimplan{1}.vta.Medium.volumeInfo.origin(2);
            Rvta.ZWorldLimits = Rvta.ZWorldLimits+thisStimplan{1}.vta.Medium.volumeInfo.origin(3);
            
            Ivta = thisStimplan{1}.vta.Medium.voxelArray;
            
            if ~exist(fullfile(thisprediction.VTAPoolPath,name),'file')
                save(fullfile(thisprediction.VTAPoolPath,name),'Rvta','Ivta');
            end
    end
end