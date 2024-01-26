function  A_loadelectrode(scene,filename)
%A_LOADELECTRODE Summary of this function goes here
%   Detailed explanation goes here
load(filename,'-mat')
e.see(scene)
end

