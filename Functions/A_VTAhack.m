function vta_raw = A_VTAhack(vtaname)


if aVTAFromAnotherLeadDesignIsAvailable(vtaname)
    vta_raw = useOtherLeadDesign(vtaname);
end

end


function [boolean,options] = aVTAFromAnotherLeadDesignIsAvailable(vtaname)
global arena
currentLeadType = getCurrentLeadType(vtaname);
SearchFor = {'Medtronic3389','Medtronic3387'};
found = {};
for iSearch = 1:numel(SearchFor)
    SearchForThis = SearchFor{iSearch};
    if strcmp(SearchForThis,currentLeadType)
        continue
    end
    trythis = strrep(vtaname,currentLeadType,SearchForThis);
    try
        VTA_raw = load(fullfile(arena.Settings.VTApool,trythis));
        found{end+1} = trythis;
    catch
        %no biggie, just continue
    end
end
boolean = not(isempty(found));
options = found;

end

function useOtherLeadDesign(vtaname)
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