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
        Space = Space.Unknown;
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
                    if isfield(arena.Settings,'VTAhack')
                        if arena.Settings.VTAhack
                            [VTA_vd,donorname] = A_VTAhack(vtaname);
                            vtaname = [vtaname, ' (based on: ',donorname,')'];
                            
                        else
                            error(['Hmm. It looks like the following VTA does not exist in your VTApool: ',vtaname])

                        end
                    else
                    end
                else
                    error('It looks like VTApool cannot be found. Maybe this folder is moved, or you have recently updated Arena. To fix this delete config.mat and restart MATLAB. Arena will then ask for the folder');
                end
            end
            
            if ~exist('VTA_vd','var')
                if ~arena.DIPS
                 VTA_raw.Rvta.XWorldLimits = VTA_raw.Rvta.XWorldLimits - VTA_raw.Rvta.PixelExtentInWorldX;
                 VTA_raw.Rvta.YWorldLimits = VTA_raw.Rvta.YWorldLimits - VTA_raw.Rvta.PixelExtentInWorldY;
                 VTA_raw.Rvta.ZWorldLimits = VTA_raw.Rvta.ZWorldLimits - VTA_raw.Rvta.PixelExtentInWorldZ;
                end
                 VTA_vd = VoxelData(VTA_raw.Ivta,VTA_raw.Rvta);
             
            end
             
             T = A_transformationmatriforleadmesh(obj.C0,obj.Direction);
             VTA_vd.imwarp(T);      
             
            VTAObject = VTA();                                                 %#ok<CPROPLC>
            VTAObject.Electrode = obj;
            VTAObject.Volume = VTA_vd;
            VTAObject.Tag = vtaname;
            
            
            obj.VTA(end+1) = VTAObject;
            
        end
        
        function saveToFolder(obj,outputfolder,tag)
            e = obj;
            save(fullfile(outputfolder,[tag,'.electrode']),'e')
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
                switch class(sceneobj) 
                    case 'ArenaScene'
                    thisScene = sceneobj;
                    case 'double'
                    thisScene = arena.sceneselect(sceneobj);
                end
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
        
        function POL = getPOL(obj,distance)
            if nargin==1
                POL = obj.C0 + obj.Direction*10; %point on lead
            else
                if numel(distance)>1
                    POL = PointCloud;
                    for i = 1:numel(distance)
                        POL.addVectors(obj.C0 + obj.Direction*distance(i),distance(i));
                    end
                else
                    POL = obj.C0 + obj.Direction*distance;
                end
            end
        end
        
        function [vertical, axial] = getAngles(obj)
            u = [sqrt(obj.Direction.x^2+obj.Direction.y^2),+obj.Direction.z];
            v = [0 1];
            
            CosTheta = max(min(dot(u,v)/(norm(u)*norm(v)),1),-1);
            vertical = real(acosd(CosTheta));
            
            %%
            u = [obj.Direction.x,obj.Direction.y];
            v = [0 1];
            CosTheta = max(min(dot(u,v)/(norm(u)*norm(v)),1),-1);
            axial = real(acosd(CosTheta));
            
            disp(['Vertical angle: ', num2str(vertical),' degrees'])
            disp(['Axial angle:    ', num2str(axial),' degrees'])
            
            
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
        
        function AC_location = getLocationOfContacts(obj)
            c = 0:3;
            AC_location = obj.C0.getArray + obj.Direction.getArray * c * obj.contactSpacing;
        end
        
        function f = LocateInImage(obj,vd)
            f = interactivePointFigure(vd,obj)
            
            
        end
            
       
    end
    
    methods(Static)
        function out = convertReco(reco) %lead-dbs
            out = Electrode.empty;
                for iElectrode = 1:numel(reco.native.coords_mm)
                    
                    e = Electrode;
                    switch reco.props(iElectrode).elmodel
                        case 'Medtronic 3389'
                            e.Type = 'Medtronic3389';
                         case 'Medtronic 3387'
                            e.Type = 'Medtronic3387';
                        case 'Boston Scientific Vercise'
                            e.Type = 'Medtronic3389';
                        otherwise
                            %please add this case.. and connect it to the
                            %appropriate arena name for the electrode.
                            keyboard
                    end
                    
                    
                    %a trial-and-error tree to find which space to use.
                    try 
                        test= reco.mni.coords_mm{iElectrode};
                        space = 'mni';
                        e.Space = Space.MNI2009b;
                    catch
                        try
                            test= reco.acpc.coords_mm{iElectrode};
                            space = 'acpc';
                            e.Space = Space.ACPC;
                        catch
                            space = 'native';
                            e.Space = Space.PatientNative;
                            
                        end
                    end
                    

                    e.C0 = reco.(space).coords_mm{iElectrode}(1,:);
                    e.PointOnLead(reco.(space).coords_mm{iElectrode}(4,:))
                    
                    out(iElectrode) = e;
                end
        end
        
        function [newVTA] = Medtronic9to7(vtaname)
            
            % this is to take C0 or C1 Medtronic 3389 VTA and move it to the
            % contact positions of 3387 - !!! aply it before transforming
            % onto the electrode!! otherwise expect complete nonsense
            
            % VTAs are small and annoying, colorfull baloons
            
            % first load Medtronic 3389 C0 or C1 3 mA VTA as usual
            % first just for 3 mA, 60 ms, later can be generalized
            
            global arena
            
            
            if isequal(vtaname, 'Medtronic33873False60c1 0 0 0a0 0 0 0.mat')
                
                
       VTA_raw = load(fullfile(arena.Settings.VTApool,'Medtronic33893False60c1 0 0 0a0 0 0 0.mat'));
       
            else
                
       VTA_raw = load(fullfile(arena.Settings.VTApool,'Medtronic33893False60c0 1 0 0a0 0 0 0.mat'));
       
            end

    VTA_raw.Rvta.XWorldLimits = VTA_raw.Rvta.YWorldLimits - VTA_raw.Rvta.PixelExtentInWorldX;
    VTA_raw.Rvta.YWorldLimits = VTA_raw.Rvta.YWorldLimits - VTA_raw.Rvta.PixelExtentInWorldY;
    VTA_raw.Rvta.ZWorldLimits = VTA_raw.Rvta.ZWorldLimits - VTA_raw.Rvta.PixelExtentInWorldZ;
    VTA_vt = VoxelData(VTA_raw.Ivta,VTA_raw.Rvta);
    
    % now we will use en emprirically derived constant (by coparison of
    % position of 3389 C0 and 3387 120 us C3), however, this constant was
    % scaled by z size of the voxels
    
    C = 1.9733;
 
    
    % in future this should be definetly generalized for different
    % ampitudes and pulswidths by decomposing the strings (now there is no time)

        % now look what VTA are we aiming for - by simple arithmetics and
        % electrode geometry, you will find out this sequence (0 1.5 3 4.5
        % is a trasnform from 0 1 2 3 ), however, from  the C1 contact on,
        % we are moving the C1 VTA
        % for 3387 contacts (3387 is 3389 elongated by factor 3/2)

        switch vtaname
    
  case 'Medtronic33873False60c1 0 0 0a0 0 0 0.mat'
        
        a = Vector3D(0,0,0);
        
  case 'Medtronic33873False60c0 1 0 0a0 0 0 0.mat'
        
        a = Vector3D(0,0,0.5*C);
        
        
  case 'Medtronic33873False60c0 0 1 0a0 0 0 0.mat'
        
        a = Vector3D(0,0,2*C);
        
  case 'Medtronic33873False60c0 0 0 1a0 0 0 0.mat'
        
        a = Vector3D(0,0,3.5*C);
        
         otherwise
        
        error('Input Medtronic 3387 VTAs of 60 ms and 3 mA')
       
        end



newVTA = VTA_vt.move(a); % now just move the 3389 VTA to the respective position

end





        
    end
end

