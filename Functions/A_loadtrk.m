function [outputArg1,outputArg2] = A_loadtrk(thisScene,filename)
%A_LOADTRK Summary of this function goes here
%   Detailed explanation goes here

[header,tracks] = ea_trk_read(filename);
F = Fibers;
for i = 1:numel(tracks)
    F.addFiber(SDK_transform3d(tracks(i).matrix, header.vox_to_ras),i)
end
F.see(thisScene)

