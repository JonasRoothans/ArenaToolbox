classdef Electrode < handle & matlab.mixin.Copyable & ArenaActorRendering
    %ELECTRODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        C0 = Vector3D([0 0 0]);
        Direction = Vector3D([0 0 1]);
        Roll = 0; % degrees, 0: C2 is anterior. 90: C2 is right
        Type = 'Medtronic3389'
        VTA = VTA.empty()
        Source
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
        
        function VTAObject = makeVTA(obj,vtaname)
            global arena
            try
             VTA_raw = load(fullfile(arena.Settings.VTApool,vtaname));
            catch
                if isfolder(arena.Settings.VTApool)
                    error(['Hmm. It looks like the following VTA does not exist in your VTApool: ',vtaname])
                else
                    error('It looks like VTApool cannot be found. Maybe this folder is moved, or you have recently updated Arena. To fix this delete config.mat and restart MATLAB. Arena will then ask for the folder');
                end
            end
            if ~arena.DIPS
             VTA_raw.Rvta.XWorldLimits = VTA_raw.Rvta.YWorldLimits - VTA_raw.Rvta.PixelExtentInWorldX;
             VTA_raw.Rvta.YWorldLimits = VTA_raw.Rvta.YWorldLimits - VTA_raw.Rvta.PixelExtentInWorldY;
             VTA_raw.Rvta.ZWorldLimits = VTA_raw.Rvta.ZWorldLimits - VTA_raw.Rvta.PixelExtentInWorldZ;
            end
             VTA_vd = VoxelData(VTA_raw.Ivta,VTA_raw.Rvta);
             
             T = A_transformationmatriforleadmesh(obj.C0,obj.Direction);
             VTA_vd.imwarp(T);      
             
            VTAObject = VTA();                                                 %#ok<CPROPLC>
            VTAObject.Electrode = obj;
            VTAObject.Volume = VTA_vd;
            VTAObject.Tag = vtaname;
            
            
            obj.VTA(end+1) = VTAObject;
            
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
        
        function PointOnLead(obj,POL)
            if ~isa(POL,'Vector3D')
                POL = Vector3D(POL);
            end
            directionvector = POL-obj.C0;
            obj.Direction = directionvector.unit();
            if isnan(obj.Direction)
                warning('Direction is NaN, visualising upside down')
                obj.Direction = Vector3D([0 0 -1]);
            end
        end
        
        function POL = getPOL(obj)
            POL = obj.C0 + obj.Direction*10; %point on lead
        end
        
        function obj = transform(obj,T)
            POL = obj.getPOL.transform(T);
            obj.C0 = obj.C0.transform(T);
            obj.PointOnLead(POL);
            
            obj.Roll = obj.Roll+rad2deg(acos(Vector3D([0 1 0]).transform(T).unit()*Vector3D([0 1 0])));
        end
        
        function obj = legacy2MNI(obj)
            %redirects to method of Vector3D
            POL = obj.getPOL.legacy2MNI();
            obj.C0 = obj.C0.legacy2MNI();
            obj.PointOnLead(POL);
        end
        
        function obj = stu2MNI(obj,MNItag)
            %redirects to method of Vector3D
            POL = obj.getPOL.stu2MNI(MNItag);
            obj.C0 = obj.C0.stu2MNI(MNItag);
            obj.PointOnLead(POL);
        end
        
        function T = getTransformFromRoot(obj)
            
            ez = obj.Direction.unit;
            ex = cross(Vector3D([sin(rad2deg(obj.Roll)), cos(rad2deg(obj.Roll)), 0]),ez);
            ey = cross(ez,ex);
            
                T = [ex.unit.getArray',0;
                ey.unit.getArray',0;
                ez.unit.getArray',0;
                obj.C0.x obj.C0.y obj.C0.z 1];
        end
        
        function T = getTransformToRoot(obj)
                T = inv(obj.getTransformFromRoot);
        end
        
        
        
        
        function bool = isLeft(obj)
            bool = obj.C0.x<0;
        end
        
        function obj = mirror(obj)
            obj.C0.x = obj.C0.x*-1;
            obj.Direction.x = obj.Direction.x*-1;
        end
            
        
        function cog = getCOG(obj)
            cog = obj.C0;
        end
        
        function distance = contactSpacing(obj)
            switch obj.Type
                case 'Medtronic3389'
                    distance = 2;
                case 'Medtronic3387'
                    distance = 3;
                case 'BostonScientific'
                    distance = 2;
                otherwise
                    keyboard
            end
            
        end
        
        function AC_location = getLocationOfAC(obj,AC)
            
            AC_location = obj.C0 + obj.Direction * mean(find(AC)-1) * obj.contactSpacing;
        end
        
        function f = LocateInImage(obj,vd)
            f = interactivePointFigure(vd,obj)
            
            
        end
            
       
    end
end

