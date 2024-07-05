function [VTA_output,donorvta] = A_VTAhack(vtaname)
if not(strcmp(vtaname(end-3:end),'.mat'))
   vtaname = [vtaname,'.mat'];
end
%check which options there are.
[yes,options] = aVTAFromAnotherLeadDesignIsAvailable(vtaname);
if yes
    if length(options)>1
        disp([num2str(length(options)), ' options available. Selected compromise: '])
        penalties = [options.Penalty];
        [lowest,index] = min(penalties);
        
        %display choice
        disp([num2str(options(index).OtherLead/2),': other lead design'])
        disp([num2str(options(index).OtherContact),': other contact '])
        disp([num2str(options(index).OtherPower),': other power source'])
        
        VTA_output = useOtherLeadDesign(vtaname,options(index));
        donorvta  = options(index).name;
        
    else
        disp([num2str(length(options)), ' option available. Selected compromise: '])
       
        
        %display choice
        disp([num2str(options(1).OtherLead/2),': other lead design'])
        disp([num2str(options(1).OtherContact),': other contact '])
        disp([num2str(options(1).OtherPower),': other power source'])
        
        VTA_output = useOtherLeadDesign(vtaname,options(1));
        donorvta  = options.name;
    end
else
    keyboard
end

end


function [boolean,options] = aVTAFromAnotherLeadDesignIsAvailable(vtaname)
global arena
options= struct;

%detect the leadtype
currentLeadType = getCurrentLeadType(vtaname);
LeadOptions = {'Medtronic3389','Medtronic3387'};

%detect the AC
[currentAC,c0] = getCurrentAC(vtaname);
if c0
    ACoptions = {'c1 0 0 0'};
else
    ACoptions = {'c0 1 0 0','c0 0 1 0','c0 0 0 1'};
end

%detect voltagecurrent
currentPower = getCurrentPower(vtaname);
PowerOptions = {'True','False'};



%check if a VTA is available from another leadtype
for iLead = 1:numel(LeadOptions)
    thisLead = LeadOptions{iLead};
    for iAC = 1:numel(ACoptions)
        thisAC = ACoptions{iAC};
        for iPower = 1:numel(PowerOptions)
            thisPower = PowerOptions{iPower};

            trythis = strrep(vtaname,currentLeadType,thisLead);
            trythis = strrep(trythis,currentAC,thisAC);
            trythis = strrep(trythis,currentPower,thisPower);

            try
                VTA_raw = load(fullfile(arena.Settings.VTApool,trythis));
                options(end+1).name = trythis;
                options(end).VTA = VTA_raw;

                %Penalty
                options(end).OtherLead = not(strcmp(thisLead,currentLeadType))*2; %Lead penalty is higher
                options(end).OtherContact = not(strcmp(thisAC,currentAC));
                options(end).OtherPower = not(strcmp(thisPower,currentPower));
                options(end).Penalty = sum([options(end).OtherLead,options(end).OtherContact,options(end).OtherPower]);
            catch
                %no biggie, just continue
            end
        end
    end
end
boolean = length(options)>1;
options(1) = []; %remove first empty one

end



function  VTA = useOtherLeadDesign(vtaname,other)
%get AC locations
AC_request = getActiveContactLocation(vtaname);
AC_compromise = getActiveContactLocation(other.name);

%find difference
translation = Vector3D([ 0 0 AC_request-AC_compromise]);

%1 voxel shift
other.VTA.Rvta.XWorldLimits = other.VTA.Rvta.XWorldLimits - other.VTA.Rvta.PixelExtentInWorldX;
other.VTA.Rvta.YWorldLimits = other.VTA.Rvta.YWorldLimits - other.VTA.Rvta.PixelExtentInWorldY;
other.VTA.Rvta.ZWorldLimits = other.VTA.Rvta.ZWorldLimits - other.VTA.Rvta.PixelExtentInWorldZ;

%move VTA
VTA = VoxelData(other.VTA.Ivta,other.VTA.Rvta);
VTA.move(translation);

end

%% Code below is to parse the strings
function AC = getActiveContactLocation(name)
leadtype = getCurrentLeadType(name);
ACstring = getCurrentAC(name);
ACindex = find(sscanf(ACstring(2:end),'%d'))-1;
switch leadtype
    case 'Medtronic3389'
        spacing = 2;
    case 'Medtronic3387'
        spacing  =3;
    case 'BostonScientific'
        spacing = 2;
end
AC = ACindex*spacing;
end

function currentPower = getCurrentPower(vtaname)
if contains(vtaname,'True')
    currentPower = 'True';
else
    currentPower = 'False';
end
end

function currentLeadType = getCurrentLeadType(vtaname)
if contains(vtaname,'Medtronic3389')
    currentLeadType = 'Medtronic3389';
elseif contains(vtaname,'Medtronic3387')
    currentLeadType = 'Medtronic3387';
elseif contains(vtaname,'StJudeMedical6142_6145')
    currentLeadType = 'StJudeMedical6142_6145';
elseif contains(vtaname,'StJudeMedical6146_6149')
    currentLeadType = 'StJudeMedical6146_6149';
elseif contains(vtaname,'BostonScientific')
    currentLeadType = 'BostonScientific';
end
end

function [currentAC,c0] = getCurrentAC(vtaname)
    [s1,s2] = regexp(vtaname,'c\d \d \d \da');
    currentAC = vtaname(s1:s2-1);
    c0 = str2num(currentAC(2)) ==1;
end