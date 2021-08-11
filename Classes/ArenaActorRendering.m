classdef ArenaActorRendering < handle
    %RENDER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Hidden)
        settings = struct;
        MATERIAL_Slicei =  [0.9 0.2 0];
        MATERIAL_ObjFile = [0.8 1 0.2];
        MATERIAL_Mesh =    [0.8 1 0.2];
        MATERIAL_Fiber =   [0.8 0.8 0.2];
    end
    
    
    methods
        function obj = ArenaActorRendering(obj)
            
        end
        
        function [settings,presets] = getDefaultSettings(obj,scene)
            switch class(obj)
                case 'PointCloud'
                    settings.colorLow = scene.getNewColor(scene);
                    settings.colorHigh = 1-scene.getNewColor(scene);
                    settings.thickness = 100;
                    settings.opacity = 100;
                case 'Fibers'
                    settings.colorFace2 = scene.getNewColor(scene);
                    settings.colorFace = [0 0 0];
                    settings.numberOfFibers = 100;
                    settings.faceOpacity = 50;
                    settings.colorByDirection = true;
                    settings.colorByWeight = false;
                    settings.colorSolid = false;
                case 'Contour'
                    settings.colorFace = scene.getNewColor(scene);
                    settings.colorEdge = scene.getNewColor(scene);%
                    settings.faceOpacity = 80;
                    settings.edgeOpacity = 0;
                case 'Mesh'
                    settings.colorFace = scene.getNewColor(scene);%[0 188 216]/255;
                    settings.colorEdge = scene.getNewColor(scene);%[0 188 216]/255;
                    settings.complexity = 20;
                    settings.threshold = NaN;
                    settings.faceOpacity = 50;
                    settings.edgeOpacity = 0;
                    settings.smooth = 1;
                case 'ObjFile'
                    settings.colorFace = scene.getNewColor(scene);
                    settings.colorEdge = scene.getNewColor(scene);
                    settings.complexity = 100;
                    settings.faceOpacity = 100;
                    settings.edgeOpacity = 0;
                    settings.smooth = 0;
                case 'Slicei'
                    settings = struct;
                    settings.colorDark = [0 0 0];
                    settings.colorLight = [1 1 1];
                    settings.valueDark = min(obj.vol(:));
                    settings.valueLight = max(obj.vol(:));
                    settings.slice = 0;
                    settings.plane = 'axial';
                    settings.faceOpacity = 90;
                    
                otherwise
                    keyboard
            end
        end
        
        
        function visualize(obj,actor,settings,scene)
            
            if nargin<3;settings = nan;end
            [settings,loadDefaultSettings] = loadDefaultSettingsWhenNoSettingsAreProvided(settings);
            
            
            switch class(obj)
                case 'Contour'
                    visualizeContour()
                case 'Electrode'
                    visualizeElectrode()
                case 'Fibers'
                    visualizeFibers()
                case 'Mesh'
                    visualizeMesh()
                case 'ObjFile'
                    visualizeObjFile()
                case 'PointCloud'
                    visualizePointCLoud()
                case 'Slicei'
                    visualizeSlice()
                case 'VectorCloud'
                    visualizeVectorCloud()
                otherwise
                    keyboard
            end
            
            %nested visualize functions
            
            function visualizeContour()
                keyboard
            end
            
            function visualizeElectrode()
                keyboard
            end
            
            function  visualizeFibers()
                % do not proceed if the actor wasn't live yet.
                if isempty(obj.ActorHandle) && ~isempty(obj.Connectome)
                    obj.ActorHandle = actor;
                    return
                elseif isempty(obj.ActorHandle) && isempty(obj.Connectome)
                    obj.ActorHandle = actor;
                    scene = actor.Scene;
                    
                else
                    actor = obj.ActorHandle;
                    scene = actor.Scene;
                end
                
                
                if isempty(obj.Connectome)
                    visualizeFibers_fromFile()
                else
                    visualizeFibers_fromConnectome();
                end

                %update actor
                actor.Visualisation.settings = settings;
                
                %update
                updateCC(actor,scene)
                
                %--end
                
                
                function  visualizeFibers_fromConnectome()
                    try
                        nFibersVisualised = numel(actor.Visualisation.handle);
                    catch
                        nFibersVisualised = 0;
                    end
                    
                    %1.----- Draw all the fibers
                    if settings.numberOfFibers ~= nFibersVisualised
                        if settings.numberOfFibers < nFibersVisualised %show less
                            
                            %delete fibers from the Fibers object
                            obj.Vertices(settings.numberOfFibers+1:end) = [];
                            obj.Indices(settings.numberOfFibers+1:end) = [];
                            
                            %delete fibers from the Actor
                            delete(actor.Visualisation.handle(settings.numberOfFibers+1:end))
                            actor.Visualisation.handle(settings.numberOfFibers+1:end) = [];
                        elseif numel(obj.Vertices)>=settings.numberOfFibers %show more
                            for n = nFibersVisualised+1:settings.numberOfFibers
                                obj = drawNewFiberInScene(obj,n);
                            end
                        else %ask the connectome to deliver more fibers:
                            getFibersPassingThroughMesh(obj.Connectome,...
                                obj.IncludeSeed,...
                                settings.numberOfFibers,...
                                scene,...
                                obj)
                            
                            %if the connectome cannot deliver more:
                            if  numel(obj.Vertices) < settings.numberOfFibers
                                settings.numberOfFibers = numel(obj.Vertices);
                            end
                            
                            for n = nFibersVisualised+1:numel(obj.Vertices)
                                obj = drawNewFiberInScene(obj,n);
                            end


                        end
                    end
                    
                    %2.----- Update the color
                    colorFiber(obj.ActorHandle)
                    
                    %3.----- To do: mirror fix
                    %check for mirroring
                    idcs_cumsum = cumsum(obj.Connectome.Data.idx);
                    iFib = obj.Indices(1);
                    try
                        start = idcs_cumsum(iFib-1)+1;
                    catch
                        start = 1;
                    end
                    
                    FirstVertex = obj.Connectome.Data.fibers(start,1);
                    
                    if not(FirstVertex==obj.Vertices(1).Vectors(1).x)
                        obj.redraw(scene,actor);
                    end
                    
                    
                end
                function visualizeFibers_fromFile()
                    try
                    delete(obj.ActorHandle.Visualisation.handle(:));
                    obj.ActorHandle.Visualisation.handle(:) = [];
                    catch
                        %no fibers were drawn yet
                    end
                    
                    for iFiber = 1:obj.ActorHandle.Visualisation.settings.numberOfFibers
                        drawNewFiberInScene(obj,iFiber)
                    end
                    
                     colorFiber(obj.ActorHandle)
                

                end
                    
                
            end
            
            function obj = drawNewFiberInScene(obj,n)
                %initialize handle array
                if not(isfield(obj.ActorHandle.Visualisation,'handle'))
                    obj.ActorHandle.Visualisation.handle = gobjects(0);
                end
                
                vertices = obj.Vertices(n).Vectors.getArray;
                h = streamtube({vertices}, 0.5,[1 3]);
                set(h,'FaceColor',[1 1 1],'EdgeAlpha',0);
                
                obj.ActorHandle.Visualisation.handle(n) = h;
            end
            
            
            
            function colorFiber(actor)
                %apply settings
                for iH = 1:numel(actor.Visualisation.handle)
                    if settings.colorByDirection
                        color = PointCloud([abs(diff(mean(actor.Visualisation.handle(iH).XData,2))),...
                            abs(diff(mean(actor.Visualisation.handle(iH).YData,2))),...
                            abs(diff(mean(actor.Visualisation.handle(iH).ZData,2)))]).Vectors.unit;
                        color = [color;color(end,:)];
                        
                        colorArray = color.getArray;
                        
                        CData = [];
                        CData(:,:,1) = repmat(colorArray(:,1),1, size(actor.Visualisation.handle(iH).CData,2));
                        CData(:,:,2) = repmat(colorArray(:,2),1, size(actor.Visualisation.handle(iH).CData,2));
                        CData(:,:,3) = repmat(colorArray(:,3),1, size(actor.Visualisation.handle(iH).CData,2));
                    end
                    if settings.colorByWeight
                        if isempty(obj.Weight)
                            settings.colorSolid = 1;
                            settings.colorByWeight = 0;
                        else
      
                        colorvalue = (obj.Weight(iH) - min(obj.Weight))/(max(obj.Weight)-min(obj.Weight));
                        low = colorvalue;
                        high = 1-low;
                        
                        lowRGB = settings.colorFace;
                        highRGB = settings.colorFace2;
                        
                        arraysize = size(actor.Visualisation.handle(iH).CData);
                        CData_template = ones(arraysize(1:2));
                        
                        CData = ones(size(actor.Visualisation.handle(iH).CData));
                        CData(:,:,1) = CData_template*lowRGB(1)*low + CData_template*highRGB(1)*high ;
                        CData(:,:,2) = CData_template*lowRGB(2)*low + CData_template*highRGB(2)*high ;
                        CData(:,:,3) = CData_template*lowRGB(3)*low + CData_template*highRGB(3)*high ;
                        end
                    end
                    if settings.colorSolid
                        arraysize = size(actor.Visualisation.handle(iH).CData);
                        CData_template = ones(arraysize(1:2));
                        CData  = [];
                        CData(:,:,1) = CData_template*settings.colorFace2(1);
                        CData(:,:,2) = CData_template*settings.colorFace2(2);
                        CData(:,:,3) = CData_template*settings.colorFace2(3);
                    end
                    
                    %color
                    actor.Visualisation.handle(iH).CData = CData;
                    actor.Visualisation.handle(iH).FaceColor = 'interp';
                    
                    %opacity
                    actor.Visualisation.handle(iH).FaceAlpha = settings.faceOpacity/100;
                    
                    %material
                    material(actor.Visualisation.handle(iH),obj.MATERIAL_Fiber)
                    
                end
            end
            
            
            
            function visualizeMesh()
                %load default settings at creation
                if not(isempty(obj.Source))
                    if isnan(settings.threshold)
                        settings.threshold = obj.Settings.T;
                    end
                end
                   
                
                %get axes
                axes(scene.handles.axes)
                
                if not(isempty(obj.Source))
                    isBasedOnVoxelData  = 1;
                    dynamicComplexity = 1;
                else
                    isBasedOnVoxelData  = 0;
                    dynamicComplexity = 0;
                end
                
                if isBasedOnVoxelData
                    if or(not(round(settings.threshold,7)==round(obj.Settings.T,7)),isa(scene,'ArenaCropMenu'))
                        if isnan(settings.threshold)
                            obj.getmeshfromvoxeldata({obj.Source});
                            settings.threshold = obj.Settings.T;
                        else
                            obj.getmeshfromvoxeldata({obj.Source,settings.threshold});
                        end
                    end
                end
                
                %create the handle
                try
                    out2=lpflow_trismooth(obj.Vertices,obj.Faces);
                    handle = patch('Faces',obj.Faces,'Vertices',out2);
                catch % if smoothing fails
                    handle = patch('Faces',obj.Faces,'Vertices',obj.Vertices);
                end
                
                %Dynamic Complexity
                if dynamicComplexity
                    complexity = 100/length(handle.Vertices);
                    if complexity>1
                        complexity = 1;
                    elseif complexity < 0.2
                        complexity = 0.2;
                    end
                    settings.complexity = complexity *100;
                    reducepatch(handle,complexity);
                else
                    reducepatch(handle,settings.complexity/100);
                end
                
                %apply settings
                handle.FaceColor = settings.colorFace;
                handle.EdgeColor = settings.colorEdge;
                handle.FaceAlpha = settings.faceOpacity/100;
                handle.EdgeAlpha = settings.edgeOpacity/100;
                if settings.smooth
                    handle.FaceLighting = 'gouraud';
                else
                    handle.FaceLighting = 'flat';
                end
                
                material(handle,obj.MATERIAL_Mesh)
                
                actor.Visualisation.handle = handle;
                actor.Visualisation.settings = settings;
                
                %update
                updateCC(actor,scene)
                
            end %done
            
            function visualizeObjFile()
                %load default settings at creation
                if not(isstruct(settings))
                    [settings] = obj.getDefaultSettings(scene);
                    creation = 1;
                else
                    creation = 0;
                end
                
                %get axes
                axes(scene.handles.axes)
                
                
                %create the handle
                handle = patch('Faces',obj.Faces,'Vertices',obj.Vertices);
                
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
                
                %set material
                material(handle,obj.MATERIAL_ObjFile)
                
                %update actor object
                actor.Visualisation.handle = handle;
                actor.Visualisation.settings = settings;
                
                %update config control
                updateCC(actor,scene)
            end %done
            
            function visualizePointCLoud()
                %load default settings at creation
                if not(isstruct(settings))
                    [settings] = obj.getDefaultSettings(scene);
                    creation = 1;
                else
                    creation = 0;
                end
                
                %set axes
                axes(scene.handles.axes)
                
                %get the vectors
                v = obj.Vectors.getArray();
                w = obj.Weights;
                
                if numel(v)==3
                    v = v';
                end
                
                %get colormap
                cmap = A_colorgradient(settings.colorLow,settings.colorHigh,256);
                w_color = A_vals2colormap(w,cmap);
                
                %scatter
                handle = scatter3(v(:,1),v(:,2),v(:,3),settings.thickness,w_color,'filled');
                alpha(handle,settings.opacity/100)
                
                %update actor class
                actor.Visualisation.handle = handle;
                actor.Visualisation.settings = settings;
                
                %update config controls
                updateCC(actor,scene)
            end %done
            
            function visualizeSlice()
                %load default settings at creation
                if not(isstruct(settings))
                    [settings] = obj.getDefaultSettings(scene);
                    creation = 1;
                else
                    creation = 0;
                end
                
                %set gradient
                cmap = A_colorgradient(settings.colorDark,settings.colorLight,255);
                obj.cmap = cmap;
                obj.dark = settings.valueDark;
                obj.light = settings.valueLight;
                obj.opacity = settings.faceOpacity/100;
                
                %set cross-section
                switch settings.plane
                    case 'axial'
                        obj.slicedim = 3;
                    case 'sagittal'
                        obj.slicedim = 1;
                    case 'coronal'
                        obj.slicedim = 2;
                end
                
                %get slice
                vector = [0 0 0];
                vector(obj.slicedim) = settings.slice;
                T = obj.I2X;
                T(4,4) = 1;
                imagespace = SDK_transform3d(vector,inv(T'));
                obj.sliceidx = imagespace(obj.slicedim);
                
                %refresh only when it already exists
                if not(creation)
                    obj.update_slice(scene);
                end
                
                %set material
                material(obj.handle,obj.MATERIAL_Slicei)
                
                %update actor class
                actor.Visualisation.handle = obj.handle;
                actor.Visualisation.settings = settings;
            end %done
            
            function visualizeVectorCloud()
                keyboard
            end
            
            function [settings,loadDefaultSettings] = loadDefaultSettingsWhenNoSettingsAreProvided(settings)
                
                
                loadDefaultSettings = 1;
                    if isstruct(settings)
                        loadDefaultSettings = 0;
                        return
                    end
      
                
                if isprop(obj,'ActorHandle')
                    if not(isempty(obj.ActorHandle))
                        settings = obj.ActorHandle.Visualisation.settings;
                        loadDefaultSettings = 0;
                    end
                end
                
                
                if loadDefaultSettings
                    [settings] = obj.getDefaultSettings(scene);
                    actor.Visualisation.settings = settings;
                end
                
            end
            
            
            
            
            
        end
    end
end

