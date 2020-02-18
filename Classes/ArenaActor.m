classdef ArenaActor < handle & matlab.mixin.Copyable
    %ARENAACTOR Connects visualisation settings to Data. Links to Scene.
    
    properties
        Data
        Visualisation
        Scene
        Tag
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
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Data = data;
            obj.Scene(end+1) = scene;
            if nargin==4
                settings = OPTIONALvisualisation;
            else
                settings = NaN;
            end
            switch class(data)
                case 'PointCloud'
                    obj.visualizePointCloud(settings,data,scene); %settings, data, scene
                    obj.Tag = 'PointCloud';
                case 'Mesh'
                    obj.visualizeMesh(settings,data,scene); %settings, data, scene
                    obj.Tag = 'Mesh';
                case 'Slice'
                    obj.visualizeSlice(settings,data,scene);
                    obj.Tag = 'Slice';
                case 'ObjFile'
                    obj.visualizeObjFile(settings,data,scene);
                    obj.Tag = 'ObjFile';
                case 'VectorCloud'
                    obj.visualizeVectorCloud(settings,data,scene);
                    obj.Tag = 'VectorCloud';
                case 'Electrode'
                    obj.visualizeElectrode(settings,data,scene);
                    obj.Tag = 'Electrode';
                otherwise
                    keyboard
            end
            
        end
        
        function settings = visualizeObjFile(obj,settings,data,scene)
            %---- default settings
            if not(isstruct(settings))
                settings = struct;
                settings.colorFace = [0.2 0.2 0.2];
                settings.colorEdge = [0.2 0.2 0.2];
                settings.complexity = 20;
                settings.faceOpacity = 10;
                settings.edgeOpacity = 0;
                settings.smooth = 0;
            end
            
            axes(scene.handles.axes)
            
            
            %create the handle
            handle = patch('Faces',data.Faces,'Vertices',data.Vertices);
            
            %apply settings
            reducepatch(handle,settings.complexity/100);
            handle.FaceColor = settings.colorFace;
            handle.EdgeColor = settings.colorEdge;
            handle.FaceAlpha = settings.faceOpacity/100;
            handle.EdgeAlpha = settings.edgeOpacity/100;
            if settings.smooth
                handle.FaceLighting = 'gouraud';
            else
                handle.FaceLighting = 'flat';
            end
            obj.Visualisation.handle = handle;
            obj.Visualisation.settings = settings;
            
            %update
            updateCC(obj,scene)
        end
        
        function settings = visualizeSlice(obj,settings,data,scene)
            %---- default settings
            if not(isstruct(settings))
                settings = struct;
                settings.colorDark = [0 0 0];
                settings.colorLight = [1 1 1];
                settings.valueDark = 0;
                settings.valueLight = 255;
                settings.baseVector = [0,0,0];
                settings.normalVector = [0, 0, 1];
                settings.faceOpacity = 90;
                settings.edgeOpacity = 0;
                settings.clipDark = 0;
            end
            
            axes(scene.handles.axes)
            
            %create the handle
            data = data.getslicefromvoxeldata(Vector3D(settings.baseVector),Vector3D(settings.normalVector));
            [gridx,gridy,gridz] = A_imref2meshgrid(data.Source.R);
            
            
            handle = slice(gridx,gridy,gridz,data.Source.Voxels,data.Plane.X,data.Plane.Y,data.Plane.Z);
            handle.FaceAlpha = settings.faceOpacity/100;
            handle.EdgeAlpha = settings.edgeOpacity/100;
            handle.FaceColor = 'interp';
            
            
            cmap = A_colorgradient(settings.colorDark,settings.colorLight,255);
            sliceVoxelValues = handle.CData;
            RGBvector = A_vals2colormap(handle.CData(:),cmap,[settings.valueDark,settings.valueLight]);
            RGB = reshape(RGBvector,[size(handle.CData),3]);
            handle.CData = RGB;
            
            if settings.clipDark
                handle.FaceColor = 'interp';
                handle.FaceAlpha = 'interp';
                handle.AlphaDataMapping = 'none';
                handle.AlphaData = double(sliceVoxelValues > settings.valueDark) * (settings.faceOpacity/100);
            end
            
            
            
            
            obj.Visualisation.handle = handle;
            obj.Visualisation.settings = settings;
            
            %update
            updateCC(obj,scene)
            
            
            
        end
        
        function settings = visualizeMesh(obj,settings,data,scene)
            %---- default settings
            if and(isempty(data.Source),not(isstruct(settings))) % mesh has no voxel image as source
                settings = struct;
                settings.colorFace = [0.2 0.2 0.8];
                settings.colorEdge = [0.2 0.2 0.8];
                settings.complexity = 100;
                settings.threshold = NaN;
                settings.faceOpacity = 50;
                settings.edgeOpacity = 0;
                settings.smooth = 1;
            else
                if not(isstruct(settings)) %mesh has been generated from voxels
                    settings = struct;
                    settings.colorFace = [0.2 0.2 0.8];
                    settings.colorEdge = [0.2 0.2 0.8];
                    settings.complexity = 100;
                    settings.threshold = data.Settings.T;
                    settings.faceOpacity = 50;
                    settings.edgeOpacity = 0;
                    settings.smooth = 1;
                end
            end
            
            axes(scene.handles.axes)
            
            isBasedOnVoxelData = not(isempty(data.Source));
            
            % changing threshold triggers new triangulation from voxeldata
            if isBasedOnVoxelData
                if not(round(settings.threshold,2)==round(data.Settings.T,2))
                    if isnan(settings.threshold)
                        data.getmeshfromvoxeldata({data.Source});
                        settings.threshold = data.Settings.T;
                    else
                        data.getmeshfromvoxeldata({data.Source,settings.threshold});
                    end
                end
            end
            
            %create the handle
            handle = patch('Faces',data.Faces,'Vertices',data.Vertices);
            
            %apply settings
            reducepatch(handle,settings.complexity/100);
            handle.FaceColor = settings.colorFace;
            handle.EdgeColor = settings.colorEdge;
            handle.FaceAlpha = settings.faceOpacity/100;
            handle.EdgeAlpha = settings.edgeOpacity/100;
            if settings.smooth
                handle.FaceLighting = 'gouraud';
            else
                handle.FaceLighting = 'flat';
            end
            obj.Visualisation.handle = handle;
            obj.Visualisation.settings = settings;
            
            %update
            updateCC(obj,scene)
        end
        
        
        function settings = visualizeVectorCloud(obj,settings,data,scene)
            %---- default settings
            if not(isstruct(settings))
                settings = struct;
                settings.color1 = [0.85 0.85 0.85];
                settings.color2 = [0.5 0.5 0.5];
                settings.color3 = [0 0 1];
                settings.scale = 5;
                settings.leadoverlay = 0;
                settings.opacity = 100;
            end
            
            axes(scene.handles.axes)
            
            
            if settings.leadoverlay ==0
                handle = [];
                for i = 1:numel(data.Base)
                    
                    primaryend = data.Base(i).getArray() + settings.scale*data.Direction(i).getArray();
                    h.primary = mArrow3(data.Base(i).getArray(),primaryend, 'facealpha', settings.opacity, 'color', settings.color1, 'stemWidth', settings.scale*0.02,'Visible','on','Clipping','off');
                    alpha(h.primary,settings.opacity/100)
                    handle(end+1) = h.primary;
                end
                
                
            else
                
                load('Arena_mdt3389.mat');
                
                handle = [];
                for i = 1:numel(data.Base)
                    T = A_transformationmatriforleadmesh(data.Base(i),data.Direction(i));
                    body = mdt3389.body.transform(T);
                    c0 = mdt3389.c0.transform(T);
                    c1 = mdt3389.c1.transform(T);
                    c2 = mdt3389.c2.transform(T);
                    c3 = mdt3389.c3.transform(T);
                    
                    
                    handle(end+1) = patch('Faces',body.Faces,'Vertices',body.Vertices,'FaceColor',settings.color1 ,'EdgeColor','none','Clipping',0,'SpecularStrength',0,'FaceAlpha',settings.opacity/100);
                    handle(end).FaceLighting = 'gouraud';
                    handle(end+1) = patch('Faces',c0.Faces,'Vertices',c0.Vertices,'FaceColor',settings.color2,'EdgeColor','none','Clipping',0,'SpecularStrength',1,'FaceAlpha',settings.opacity/100);
                    handle(end).FaceLighting = 'gouraud';
                    handle(end+1) = patch('Faces',c1.Faces,'Vertices',c1.Vertices,'FaceColor',settings.color2,'EdgeColor','none','Clipping',0,'SpecularStrength',1,'FaceAlpha',settings.opacity/100);
                    handle(end).FaceLighting = 'gouraud';
                    handle(end+1) = patch('Faces',c2.Faces,'Vertices',c2.Vertices,'FaceColor',settings.color2,'EdgeColor','none','Clipping',0,'SpecularStrength',1,'FaceAlpha',settings.opacity/100);
                    handle(end).FaceLighting = 'gouraud';
                    handle(end+1) = patch('Faces',c3.Faces,'Vertices',c3.Vertices,'FaceColor',settings.color2,'EdgeColor','none','Clipping',0,'SpecularStrength',1,'FaceAlpha',settings.opacity/100);
                    handle(end).FaceLighting = 'gouraud';
                    
                end
                
            end

            obj.Visualisation.handle = handle;
            obj.Visualisation.settings = settings;
            
            updateCC(obj,scene)
        end
        
                function settings = visualizeElectrode(obj,settings,data,scene)
            %---- default settings
            if not(isstruct(settings))
                settings = struct;
                settings.colorBase = [0.85 0.85 0.85];
                settings.colorInactive = [0.5 0.5 0.5];
                settings.colorCathode = [1 0.5 0];
                settings.colorAnode = [0 0.5 1];
                settings.cathode = [0 0 0 0];
                settings.anode = [0 0 0 0];
                settings.opacity = 100;
                settings.type = data.Type;
            end
            
            axes(scene.handles.axes)
            
            if strcmp(settings.type,'Medtronic3389')
                leadmodel = load('Arena_mdt3389.mat');
                strucname = 'mdt3389';
            elseif strcmp(settings.type,'Medtronic3387')
                leadmodel = load('Arena_mdt3387.mat');
                strucname = 'mdt3387';
            elseif strcmp(settings.type,'Medtronic3391')
                leadmodel = load('Arena_mdt3391.mat');
                strucname = 'mdt3391';
            elseif strcmp(settings.type,'BostonScientific')
                 leadmodel = load('Arena_BostonScientific.mat');
                 strucname = 'BostonScientific';
              else
                error('leadtype is currently not yet supported!')   
              end
                
                handle = gobjects(0);

                    T = A_transformationmatriforleadmesh(data.C0,data.Direction);
                    body = leadmodel.(strucname).body.transform(T);
                    handle(end+1) = patch('Faces',body.Faces,'Vertices',body.Vertices,'FaceColor',settings.colorBase ,'EdgeColor','none','Clipping',0,'SpecularStrength',0,'FaceAlpha',settings.opacity/100);
                    
                    for i = 0:numel(fieldnames(leadmodel.(strucname)))-2
                    ci = leadmodel.(strucname).(['c',num2str(i)]).transform(T);
                    handle(end+1) = patch('Faces',ci.Faces,'Vertices',ci.Vertices,'FaceColor',settings.colorInactive,'EdgeColor','none','Clipping',0,'SpecularStrength',1,'FaceAlpha',settings.opacity/100);
                    end
                    
                    for i = 1:numel(settings.cathode)
                        if settings.cathode(i)
                            handle(1+i).FaceColor = settings.colorCathode;
                        end
                    end
                    for i = 1:numel(settings.anode)
                        if settings.anode(i)
                            handle(1+i).FaceColor = settings.colorAnode;
                        end
                    end
              
                
            
            obj.Visualisation.handle = handle;
            obj.Visualisation.settings = settings;
            
            updateCC(obj,scene)
                end
        
        
        function settings = visualizePointCloud(obj,settings,data,scene)
            %---- default settings
            if not(isstruct(settings))
                settings = struct;
                settings.colorLow = [1 0 0];
                settings.colorHigh = [0 0 1];
                settings.thickness = 100;
                settings.opacity = 100;
            end
            
            axes(scene.handles.axes)
            
            v = data.Vectors.getArray();
            w = data.Weights;
            
            if numel(v) ==3
                v = v';
            end
            cmap = A_colorgradient(settings.colorLow,settings.colorHigh,256);
            w_color = A_vals2colormap(w,cmap);
            
            handle = scatter3(v(:,1),v(:,2),v(:,3),settings.thickness,w_color,'filled');
            
            alpha(handle,settings.opacity/100)
            
            obj.Visualisation.handle = handle;
            obj.Visualisation.settings = settings;
            
            updateCC(obj,scene)
            
            
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
            
            delete(obj.Visualisation.handle);
            switch class(obj.Data)
                case 'PointCloud'
                    visualizePointCloud(obj,obj.Visualisation.settings,obj.Data,obj.Scene)
                case 'Mesh'
                    visualizeMesh(obj,obj.Visualisation.settings,obj.Data,obj.Scene)
                case 'ObjFile'
                    visualizeObjFile(obj,obj.Visualisation.settings,obj.Data,obj.Scene)
                case 'Electrode'
                    visualizeElectrode(obj,obj.Visualisation.settings,obj.Data,obj.Scene)
                otherwise
                    keyboard
            end
        end
        
        function updateCC(obj,scene)
            settings = obj.Visualisation.settings;
            scene.clearconfigcontrols()
            switch class(obj.Data)
                case 'PointCloud'
                    scene.newconfigcontrol(obj,'color',{settings.colorLow, settings.colorHigh},{'colorLow','colorHigh'});
                    scene.newconfigcontrol(obj,'edit',settings.thickness,'thickness');
                    scene.newconfigcontrol(obj,'edit',settings.opacity,'opacity');
                case 'Mesh'
                    scene.newconfigcontrol(obj,'color',{settings.colorFace,settings.colorEdge},{'colorFace','colorEdge'});
                    scene.newconfigcontrol(obj,'edit',{settings.complexity,settings.threshold},{'complexity','threshold'});
                    scene.newconfigcontrol(obj,'edit',settings.faceOpacity,'faceOpacity')
                    scene.newconfigcontrol(obj,'edit',settings.edgeOpacity,'edgeOpacity')
                    scene.newconfigcontrol(obj,'checkbox',settings.smooth,'smooth')
                case 'ObjFile'
                    scene.newconfigcontrol(obj,'color',{settings.colorFace,settings.colorEdge},{'colorFace','colorEdge'});
                    scene.newconfigcontrol(obj,'edit',{settings.complexity},{'complexity'});
                    scene.newconfigcontrol(obj,'edit',settings.faceOpacity,'faceOpacity')
                    scene.newconfigcontrol(obj,'edit',settings.edgeOpacity,'edgeOpacity')
                    scene.newconfigcontrol(obj,'checkbox',settings.smooth,'smooth')
                case 'VectorCloud'
                    scene.newconfigcontrol(obj,'color',{settings.color1,settings.color2,settings.color3},{'color1','color2','color3'});
                    scene.newconfigcontrol(obj,'edit',settings.scale,'scale');
                    scene.newconfigcontrol(obj,'edit',settings.opacity,'opacity');
                    scene.newconfigcontrol(obj,'checkbox',settings.leadoverlay,'leadoverlay');
                case 'Slice'
                    scene.newconfigcontrol(obj,'color',{settings.colorDark,settings.colorLight},{'colorDark','colorLight'});
                    scene.newconfigcontrol(obj,'edit',{settings.valueDark,settings.valueLight},{'valueDark','valueLight'});
                    scene.newconfigcontrol(obj,'vector',{settings.baseVector,settings.normalVector},{'baseVector','normalVector'});
                    scene.newconfigcontrol(obj,'edit',{settings.faceOpacity,settings.edgeOpacity},{'faceOpacity','edgeOpacity'});
                    scene.newconfigcontrol(obj,'checkbox',settings.clipDark,'clipDark');
                case 'Electrode'
                    scene.newconfigcontrol(obj,'color',{settings.colorBase,settings.colorInactive},{'colorBase','colorInactive'});
                    scene.newconfigcontrol(obj,'color',{settings.colorCathode,settings.colorAnode},{'colorCathode','colorAnode'});
                    scene.newconfigcontrol(obj,'vector',{settings.cathode,settings.anode},{'cathode','anode'});
                    scene.newconfigcontrol(obj,'edit',{settings.opacity},{'opacity'});
                    scene.newconfigcontrol(obj,'list',{settings.type},{'type'},{'Medtronic3389','Medtronic3387','Medtronic3391','BostonScientific'})
                    
                otherwise
                    keyboard
            end
        end
        
        function updateActor(obj,scene,settings)
            delete(obj.Visualisation.handle);
            
            %replace nans with current values
            currentsettings = obj.Visualisation.settings;
            props = fieldnames(currentsettings);
            for i = 1:numel(props)
                if isnan(settings.(props{i}))
                    settings.(props{i}) = currentsettings.(props{i});
                end
            end
            
            switch class(obj.Data)
                case 'PointCloud'
                    visualizePointCloud(obj,settings,obj.Data,scene)
                case 'Mesh'
                    visualizeMesh(obj,settings,obj.Data,scene)
                case 'ObjFile'
                    visualizeObjFile(obj,settings,obj.Data,scene)
                case 'VectorCloud'
                    visualizeVectorCloud(obj,settings,obj.Data,scene)
                case 'Slice'
                    visualizeSlice(obj,settings,obj.Data,scene)
                case 'Electrode'
                    visualizeElectrode(obj,settings,obj.Data,scene)
                otherwise
                    keyboard
            end
        end
        
        function changeName(obj,name)
            obj.Tag = name;
            obj.Scene.refreshLayers();
        end
        
        function export3d(obj,name)
            switch class(obj.Data)
                case 'Mesh'
                    vertface2obj(obj.Data.Vertices,obj.Data.Faces,name)
                otherwise
                    keyboard
            end
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
            function obj = applyT(obj,T)
                switch class(obj.Data)
                    case 'PointCloud'
                        v = obj.Data.Vectors.getArray;
                        v_transformed = SDK_transform3d(v,T);
                        obj.Data.Vectors = v_transformed;
                        obj.updateActor(scene,obj.Visualisation.settings);
                        
                    case 'Mesh'
                        Source = obj.Data.Source;
                        [imOut,rOut] = imwarp(Source.Voxels,Source.R,affine3d(diag([-1 1 1 1])));
                        v = obj.Data.Vertices;
                        v_transformed = SDK_transform3d(v,T);
                        obj.Data.Vertices = v_transformed;
                        newSource = VoxelData(imOut,rOut);
                        obj.Data.Source = newSource;
                        obj.Visualisation.handle = []; %remove old handle
                        obj.updateActor(scene,obj.Visualisation.settings);
                    case 'ObjFile'
                        v = obj.Data.Vertices;
                        v_transformed = SDK_transform3d(v,T);
                        obj.Data.Vertices = v_transformed;
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
                    answer = questdlg(question,'Arena','change name','delete actor','cancel','cancel');
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
                case 'cancel'
                    return
            end
            
        end
        
        function copyobj = duplicate(obj,scene)
            copyobj = copy(obj);
            if isa(copyobj.Data,'Mesh')
                copyobj.Data = copyobj.Data.duplicate;
            end
            scene.Actors(end+1) = copyobj;
            scene.refreshLayers();
        end
        
        function delete(obj,scene)
            currentIndex = find(scene.Actors==obj);
            scene.Actors(currentIndex) = [];
            delete(obj.Visualisation.handle)
            scene.refreshLayers();
        end
        
        function newActor = reviveInScene(obj,scene)
            newActor = scene.newActor(obj.Data,obj.Visualisation.settings);
            newActor.changeName(['* ',obj.Tag]);
            
        end
    end
end

