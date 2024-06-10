function [F] = A_loadtrk(thisScene,filename)
%A_LOADTRK Summary of this function goes here
%   Detailed explanation goes here

[header,tracks] = ea_trk_read(filename);
F = Fibers;
for i = 1:numel(tracks)
    F.addFiber(SDK_transform3d(tracks(i).matrix, header.vox_to_ras),i)
end

if not(isnan(thisScene))
    F.see(thisScene)
    
end

