function [] = HeatmapMaker_Lazy(menu,eventdata,scene)
%HEATMAPMAKER_LAZY Summary of this function goes here
%   Detailed explanation goes here
    global ArenaLazy
    switch menu.Checked
        case 'on'
            ArenaLazy = false;
            menu.Checked = 'off';

        case 'off'
            ArenaLazy = true;
            menu.Checked = 'on';

    end
end

