classdef Contour
    %PATCH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        patch
    end
    
    methods
        function obj = Contour(p)
            %PATCH Construct an instance of this class
            %   Detailed explanation goes here
            obj.patch = p;
        end
        

        function [thisActor,thisScene] = see(obj, sceneobj)
            global arena
            if nargin==1
                if isempty(arena)
                    evalin('base','startArena');
                    thisScene = arena.sceneselect(1);
                else
                    thisScene = arena.sceneselect();
                end
            else
                thisScene = sceneobj;
            end
            
            if isempty(thisScene);return;end %user cancels
            thisActor = thisScene.newActor(obj);

        end
        
       
    end
end

