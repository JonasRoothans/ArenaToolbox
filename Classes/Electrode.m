classdef Electrode < handle & matlab.mixin.Copyable
    %ELECTRODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        C0 = Vector3D([0 0 0]);
        Direction = Vector3D([0 0 1]);
        Type = 'Medtronic3389'
        Settings
        Source
        maxStimPlans
        c0
    end
    
    methods
        function obj = Electrode(varargin)
            if nargin==0
                return
            end
            if nargin==2
                obj.C0 = varargin{1};
                obj.Direction = varargin{2};
            end
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
        
        function set.C0(obj,C0)
            if ~isa(C0,'Vector3D')
                C0 = Vector3D(C0);
            end
            obj.C0 = C0;
        end
        
        function set.Direction(obj,Direction)
            if ~isa(Direction,'Vector3D')
                Direction = Vector3D(Direction);
            end
            obj.Direction = Direction.unit;
        end
        
        function cog = getCOG(obj)
            cog = obj.C0;
        end
       
    end
end

