function [Scene] = openscn(inputArg1)
%OPENSCN Clicking *.scn file triggers this function
loaded = load(inputArg1,'-mat');
Scene = loaded.Scene;

isSameVersion(Scene,'show');
            
end

