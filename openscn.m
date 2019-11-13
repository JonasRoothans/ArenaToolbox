function [Scene] = openscn(inputArg1)
%OPENSCN Summary of this function goes here
%   Detailed explanation goes here
loaded = load(inputArg1,'-mat');
Scene = loaded.Scene;
end

