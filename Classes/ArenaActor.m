classdef ArenaActor < handle & matlab.mixin.Copyable
    %ARENAACTOR is the vehicle for data visualisation in a Scene.
    %   It has 4 properties:
    %   - Data
    %       This stores the data object such as POINTCLOUD or MESH
    %   - Visualisation
    %       Contains handle and settings to the 3D renderings
    %   - Scene
    %       provides the handle to the ArenaScene object
    %   - Tag
    %       Name
    %   - Visible
    %       Boolean, (1 or 0) whether this layer is visible or not.
    %   See also ARENASCENE POINTCLOUD MESH FIBERS
    
    
    properties
        Data
        Visualisation
        Scene
        Tag
        Visible = true;
    end
    
    methods
        function obj = ArenaActor()
            %ACTOR Construct an instance of this class
            %   Detailed explanation goes here
            obj.Data = [];
            obj.Visualisation = [];
            obj.Scene = ArenaScene.empty;
            
        end
        
        function obj = create(obj,data,scene,OPTIONALvisualisation)
            obj.Data = data;
            try
                obj.Scene(end+1) = scene;
            catch
                %wont work if it's not a scene; but a cropmenu
            end
            
            if nargin==4
                settings = OPTIONALvisualisation;
            else
                settings = NaN;
            end
            
            visualize(obj,settings,data,scene)
            obj.Tag = class(data);
            
        end
        

        function getSettings(obj)
            disp(obj.Visualisation.settings)
        end
        
        function cog = getCOG(obj)
            cog = obj.Data.getCOG;
        end
        
        function changeSetting(obj,varargin)
            if rem(numel(varargin),2) %isodd
                error('input arguments should be pairs')
            end
            for iPair = 1:2:numel(varargin)
                if not(isfield(obj.Visualisation.settings,varargin{iPair}))
                    error([varargin{iPair},' is not a valid property'])
                end
                obj.Visualisation.settings.(varargin{iPair}) = varargin{iPair+1};
            end
            
            if not(or(or(isa(obj.Data,'Slicei'),...
                    isa(obj.Data,'Fibers')),...
                    isa(obj.Data,'Contour')))
                    delete(obj.Visualisation.handle);
            end
            
            visualize(obj,obj.Visualisation.settings,obj.Data,obj.Scene)
            obj.Scene.refreshLayers();
        end
        
        function updateCC(obj,scene)
            settings = obj.Visualisation.settings;
            scene.clearconfigcontrols()
            obj.Data.updateConfigControls(obj,settings,scene);

        end
        
        function updateActor(obj,scene,settings)
            
            if not(or(or(isa(obj.Data,'Slicei'),...
                    isa(obj.Data,'Fibers')),...
                    isa(obj.Data,'Contour')))
                delete(obj.Visualisation.handle);
            end
            
            %replace nans with current values
            currentsettings = obj.Visualisation.settings;
            props = fieldnames(currentsettings);
            for i = 1:numel(props)
                if isnan(settings.(props{i}))
                    settings.(props{i}) = currentsettings.(props{i});
                end
            end

            visualize(obj,settings,obj.Data,scene);
        end
        
        

        
      
        function settings = visualize(obj,settings,data,scene)
            %Important: The first property you add to Settings must be COLOR!
            %Because this will be used for the layer indication
            data.visualize(obj,settings,scene) %refers to the visualize method in the class. (Google: Function Precedence Order MATLAB)
        end
        
        function changeName(obj,name)
            if iscell(name)
                obj.Tag=strjoin(name); % if name is made of multiple separate parts(cells)
            else
            obj.Tag = name;
            end
            obj.Scene.refreshLayers();
        end
        
        function export3d(obj,directoryname)
            
           
            A_writeObjFile(obj,directoryname)

        end
        
        function saveToFolder(obj,outdir)
            data = obj.Data;
            data.saveToFolder(outdir,obj.Tag);
            Done;
        end
        
        function transform(obj,scene,varargin)
            if numel(varargin)>0
                switch varargin{1}
                    case 'lps2ras'
                        T = diag([-1 -1 1 1]);
                        obj = applyT(obj,T)
                    case 'mirror'
                        T = diag([-1 1 1 1]);
                        obj = applyT(obj,T)
                    case 'Fake2MNI'
                        T = [-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1];
                        obj = applyT(obj,T);
                    case 'T'
                        T = varargin{2};
                        obj = applyT(obj,T)
                end
            end
            
            %TO DO: THIS SWITCH SHOULD BE AVOIDED.
            %INSTEAD: DO OBJ.DATA.APPLYT() AND PUT THE METHOD IN THE DATACLASS
            function obj = applyT(obj,T)
                switch class(obj.Data)
                    case 'PointCloud'
                        v = obj.Data.Vectors.getArray;
                        if size(v,2)==1
                            v = v';
                        end
                        v_transformed = SDK_transform3d(v,T);
                        obj.Data.Vectors = v_transformed;
                        obj.updateActor(scene,obj.Visualisation.settings);
                        
                    case 'Mesh'
                        Source = obj.Data.Source;
                        if not(isempty(Source))
                            if any(isnan(Source.Voxels))
                                answer = questdlg('The data contains NaN values, if you proceed these will be changed to 0','Oops!','Yes, change them to 0','No I will find another way','Yes, change them to 0');
                                switch answer
                                    case 'Yes, change them to 0'
                                        Source.Voxels(isnan(Source.Voxels)) = 0;
                                    case 'No I will find another way'
                                        return
                                end
                            end
                        end
                        if not(isempty(Source))
                            [imOut,rOut] = imwarp(Source.Voxels,Source.R,affine3d(T));
                            newSource = VoxelData(imOut,rOut);
                            obj.Data.Source = newSource;
                        end
                        v = obj.Data.Vertices;
                        v_transformed = SDK_transform3d(v,T);
                        obj.Data.Vertices = v_transformed;
                        delete(obj.Visualisation.handle)
                        obj.Visualisation.handle = []; %remove old handle
                        obj.updateActor(scene,obj.Visualisation.settings);
                    case 'ObjFile'
                        v = obj.Data.Vertices;
                        v_transformed = SDK_transform3d(v,T);
                        obj.Data.Vertices = v_transformed;
                        obj.updateActor(scene,obj.Visualisation.settings);
                    case 'Electrode'
                        obj.Data.C0 = obj.Data.C0.transform(T);
                        delete(obj.Visualisation.handle)
                        obj.visualizeElectrode(obj.Visualisation.settings,obj.Data,scene)
                        
                        warning('Electrode can not be transformed like this')
                
                        
                        %obj.updateActor(scene,obj.Visualisation.settings);
                    case 'Fibers'
                        for iFiber = 1:numel(obj.Data.Vertices)
                            obj.Data.Vertices(iFiber) = obj.Data.Vertices(iFiber).transform(T);

                        end
                        obj.updateActor(scene,obj.Visualisation.settings);
                        
                    otherwise
                        
                        keyboard
                end
                
            end
            
        end
        
        function edit(obj,scene)
            question = ['Edit ',obj.Tag];
            switch class(obj.Data)
                otherwise
                    answer = questdlg(question,'Arena','change name','delete actor','get graphical handle in workspace','get graphical handle in workspace');
            end
            switch answer
                case 'change name'
                    newname = inputdlg('Change name','Arena',[1 40],{obj.Tag});
                    obj.Tag = newname{1};
                    scene.refreshLayers();
                case 'delete actor'
                    rusure = questdlg(['You are about to delete ',obj.Tag],'Arena','delete','cancel','cancel');
                    switch rusure
                        case 'delete'
                            delete(obj,scene)
                        case 'cancel'
                            return
                    end
                case 'change threshold'
                    keyboard
                case 'get graphical handle in workspace'
                    h= obj.Visualisation.handle;
                    assignin('base','h',h)
                    home;
                    disp('visualisation handle is available as ''h'' in workspace.')
                    
                    h %on purpose
                    return
            end
            
        end
        
        function copyobj = duplicate(obj,scene)
            copyobj = copy(obj);
            copyobj.Data  = copy(obj.Data);
%             switch class(copyobj.Data)
%                 case 'Mesh'
%                     copyobj.Data = copyobj.Data.duplicate;
%                     copyobj.Visualisation.handle = copy(obj.Visualisation.handle);
%                 case 'Electrode'
%                     for iSubPatch = 1:numel(copyobj.Visualisation.handle)
%                         copyobj.Visualisation.handle(iSubPatch) = copy(copyobj.Visualisation.handle(iSubPatch));
%                     end
%                 case 'Fibers'
%                     copyobj.Data = obj.Data.duplicate;
%                     copyobj.Data.ActorHandle = copyobj;
%                 case 'PointCloud'
%                     copyobj.Visualisation.handle = copy(obj.Visualisation.handle);
%                 otherwise
%                     copyobj.Visualisation.handle = copy(obj.Visualisation.handle);
%                     %if it crashes here: make a new case for this class.
%                 
%             end
            copyobj = copyobj.reviveInScene(scene);
            %scene.refreshLayers();
        end
        
        
        function delete(obj,scene)
            if nargin==1
                scene = obj.Scene;
            end
                    
            currentIndex = find(scene.Actors==obj);
            scene.Actors(currentIndex) = [];
            try
            delete(obj.Visualisation.handle)
            catch
                disp('deleted empty actor')
            end
            scene.refreshLayers();
        end
        
        function newActor = reviveInScene(obj,scene)
            newActor = scene.newActor(obj.Data,obj.Visualisation.settings);
            newActor.changeName(obj.Tag);
            
        end
        
        function Visibility(obj,command)
            switch command
                case 'toggle'
                    obj.Visible = not(obj.Visible);
                case 'hide'
                    obj.Visible = false;
                case 'unhide'
                    obj.Visible = true;
            end
                            
        end
            
        function set.Visible(obj,value)
            obj.Visible = value;
            if value
                for iHandle = 1:numel(obj.Visualisation.handle)
                    if isstruct(obj.Visualisation.handle(iHandle))
                        obj.Visualisation.handle(iHandle).Visible = 'on';
                    elseif ishandle(obj.Visualisation.handle(iHandle))
                        set( obj.Visualisation.handle(iHandle),'Visible','on');
                    end
                end
            else
                for iHandle = 1:numel(obj.Visualisation.handle)
                    if isstruct(obj.Visualisation.handle(iHandle))
                    obj.Visualisation.handle(iHandle).Visible = 'off';
                    elseif ishandle(obj.Visualisation.handle(iHandle))
                        set( obj.Visualisation.handle(iHandle),'Visible','off');
                    end
                end
            end
        
        end
        
        function callback(obj,value)
            switch value
                case 'crop'
                    cropMesh(obj)
                case 'slice'
                    switch class(obj.Data)
                        case 'Mesh'
                            actor = obj.Data.Source.getslice.see(obj.Scene);
                            actor.changeName(obj.Tag)
                        otherwise
                            keyboard
                    end
                case 'mesh'
                    actor = obj.Data.parent.getmesh.see(obj.Scene);
                    actor.changeName(obj.Tag)
                otherwise
                    num = str2num(value);
                    if not(isempty(num))
                        feval(obj.Scene.handles.btn_updateActor.Callback,obj.Scene.handles.btn_updateActor,[])
                    end
            end
                    
        end
        
        %--- mesh callbacks
        function cropMesh(obj)
            cropwindow = ArenaCropMenu;
            cropwindow.load(obj);
        end
    end
end

