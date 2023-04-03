classdef Fibers < handle & matlab.mixin.Copyable & ArenaActorRendering
    %MESH Contains Faces and Vertices. Can be initialised with VoxelData
    
    properties
        Vertices = PointCloud.empty
        Indices = [];
        Weight = [];
        IncludeSeed = Mesh.empty
        Connectome
        Settings
        ActorHandle
    end
    
    %Default visualisation Settings
    properties (Hidden)
        FIBERTHICKNESS = 0.5
        FIBERCIRCUMFERRENCE = [1, 3] %scale, nvertices
        MATERIALSHADING = [0.8,	0.8,	0.0,	10,		1.0];
        
    end
    
   
    
    methods
        function obj = Fibers(varargin)
            %MESH Construct an instance of this class
            %   Detailed explanation goes here
                if nargin==0
                    return
                end
%                 if isa(varargin{1},'Mesh')
%                     obj.getFibersPassingThroughMesh(varargin);
%                     obj.SeedInclude = varargin{1};
%                 end
        end
            
        function cog = getCOG(obj)
            cog = obj.Vertices(1).getCOG;
        end
        
        
        function newFibers = filter(obj,boolean)
            newFibers = Fibers;
            newFibers.Vertices = obj.Vertices(boolean);
            newFibers.Indices = obj.Indices(boolean);
            newFibers.Weight = obj.Weight(boolean);
            
        end
            

        
        
        function obj = drawVTKfibers(obj,actor,scene)
            axes(scene.handles.axes)
            obj.ActorHandle = actor;
            
            %delete all
            try
            delete(obj.ActorHandle.Visualisation.handle(:));
            obj.ActorHandle.Visualisation.handle(:) = [];
            catch
                %no fibers were drawn yet
            end

                
            for iFiber = 1:obj.ActorHandle.Visualisation.settings.numberOfFibers
                vertices = obj.Vertices(iFiber).Vectors.getArray;
                h = streamtube({vertices}, obj.FIBERTHICKNESS,obj.FIBERCIRCUMFERRENCE);
                
                if obj.ActorHandle.Visualisation.settings.colorByDirection
                    color = PointCloud(abs(diff(vertices,1))).Vectors.unit;
                    color = [color;color(end,:)];
                    colorArray = color.getArray;
                elseif obj.ActorHandle.Visualisation.settings.colorByWeight && not(isempty(obj.Weight))
                   colorvalue = (obj.Weight(iFiber) - min(obj.Weight))/(max(obj.Weight)-min(obj.Weight));
                   high = colorvalue;
                   low = 1-high;
                   
                   lowRGB = obj.ActorHandle.Visualisation.settings.colorFace;
                   highRGB = obj.ActorHandle.Visualisation.settings.colorFace2;
                   CData = ones(size(h.XData,1),3);
                   CData(:,1) = CData(:,1)*low*lowRGB(1)+CData(:,1)*high*highRGB(1);
                   CData(:,2) = CData(:,2)*low*lowRGB(2)+CData(:,2)*high*highRGB(2);
                   CData(:,3) = CData(:,3)*low*lowRGB(3)+CData(:,3)*high*highRGB(3);
                   colorArray = CData;
                    
                    else
                        CData = ones(size(h.XData,1),3);
                        CData(:,1) = CData(:,1)*obj.ActorHandle.Visualisation.settings.colorFace(1);
                        CData(:,2) = CData(:,2)*obj.ActorHandle.Visualisation.settings.colorFace(2);
                        CData(:,3) = CData(:,3)*obj.ActorHandle.Visualisation.settings.colorFace(3);
                        colorArray = CData;
                end
                
                streamFaceColors = [];
                streamFaceColors(:,:,1) = repmat(colorArray(:,1),1, 3+1);
                streamFaceColors(:,:,2) = repmat(colorArray(:,2),1, 3+1);
                streamFaceColors(:,:,3) = repmat(colorArray(:,3),1, 3+1);
                
                
                
                set(h, 'FaceColor', 'interp', 'CData', streamFaceColors, 'CDataMapping', 'direct', 'EdgeColor', 'none', 'FaceAlpha', obj.ActorHandle.Visualisation.settings.faceOpacity/100);
                material(h,obj.MATERIALSHADING) 
                obj.ActorHandle.Visualisation.handle(iFiber) = h;
                
            end
            
            
        end
        
        function obj = addFiber(obj,vertices,fiberindex,OPTIONALweight)
                    n = numel(obj.Vertices)+1;
                    obj.Vertices(n) = PointCloud(vertices);
                    obj.Indices(n) = fiberindex;
                    if nargin==4
                        obj.Weight(n) = OPTIONALweight;
                    end
        end

            
            
        

        
        function copyobj = duplicate(obj)
            copyobj = copy(obj);
        end
            

        function [thisActor,thisScene] = connectToScene(obj,thisScene)
            
             thisActor = thisScene.newActor(obj);
             obj.ActorHandle = thisActor;
        end
        
        function redraw(obj,scene,actor)
%             idcs_cumsum = cumsum(obj.Connectome.Data.idx);
%             iFib = obj.Indices(1);
%             try
%             start = idcs_cumsum(iFib-1)+1;
%             catch
%                 start = 1;
%             end
%             ending = idcs_cumsum(iFib);
                actor.Visualisation.handle = [];
                Vertices = obj.Vertices;
                obj.Vertices = PointCloud.empty();
                Indices = obj.Indices;
                obj.Indices = [];
                
                
                for iH = 1:numel(Indices)
                       obj.drawNewFiberInScene(Vertices(iH).Vectors.getArray,Indices(iH),scene);
                       
               end
        end
        
        
        
        function [thisActor,thisScene] = see(obj, sceneobj, OPTIONALfibercount)
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
            
            if nargin<3
                thisActor = thisScene.newActor(obj);
            else
                thisActor = thisScene.newActor(obj,OPTIONALfibercount);
            end
                
            
%             figure;
%             p= patch('Faces',obj.Faces,'Vertices',obj.Vertices);
%             
%             p.FaceColor = [0.3 0.6 0.8];
%             p.EdgeColor = 'none';
%             daspect([1 1 1])
%             view(3);
%             axis tight
%             camlight
%             lighting gouraud
        end
        
        function saveToFolder(obj,outdir,tag)
            %template space
           templateSpace_mni2009b = VoxelData(zeros([467,   395,   379]),...
               imref3d([467, 395, 379],... % size
               [-98.2500, 99.2500],... %x world
               [-134.2500, 99.2500],... %y world
               [-72.2500, 117.2500])); %z world 
           
           try
           fibervertices = obj.Connectome.quickFibersPassingThroughMesh(obj.IncludeSeed,obj.ActorHandle.Scene);
           catch
               lengths = arrayfun(@(x) x.length,obj.Vertices);
               n = sum(lengths);
               indx = [1,cumsum(lengths)+1];
               fibervertices = zeros(n,3);
              fibervertices = [];
              for iFib = 1:numel(obj.Vertices)
                  
                  fibervertices(indx(iFib):indx(iFib+1)-1,:) = obj.Vertices(iFib).Vectors.getArray;
              end
              
           end
           
           % get the voxels where fibers are passing
           disp('Projecting to MNI')
               [x,y,z] = templateSpace_mni2009b.R.worldToSubscript(fibervertices(:,1)',... %x
                   fibervertices(:,2)',... %y
                   fibervertices(:,3)');%z
                sparse3D = ndSparse.build([x',y',z'],1);
           

            disp('Add up fibers')
            template = full(sparse3D);
            template(467, 395, 379) = 0;
            
            
            warning('Work in progress!!')
            templateSpace_mni2009b.Voxels = template;
            %templateSpace_mni2009b.getmesh.see(obj.ActorHandle.Scene)
            
            templateSpace_mni2009b.savenii(fullfile(outdir,[tag,'.nii']))
               
               
           
           
        end
        
        function percentage = percentageHitByROI(obj,ROI)
            %first join all fibers for quick processing
            [Vectors,FiberIndices] = joinBundle;
            
            if not(isa(ROI,'Mesh'));keyboard;end %add other options here?)
      
            %check for all vertices which one is inside the roi if it is a
            %mes
            mapvalue = ROI.isInside(Vectors);
            
            %deconstruct into hitlist and get percentage
            hitlist = zeros(size(FiberIndices));
            for i = 1:numel(obj.Vertices)
                   hitlist(i)= max(mapvalue(FiberIndices(i):FiberIndices(i+1)-1));
            end
            percentage = nnz(hitlist)/numel(hitlist);
            
            
            function [Vectors,FiberIndices] = joinBundle()
            nVectorsPerFiber = arrayfun(@(x) length(x.Vectors),obj.Vertices);
                    Vectors = Vector3D.empty(sum(nVectorsPerFiber),0); %empty allocation
                    FiberIndices = [0,cumsum(nVectorsPerFiber)]+1;
                    weights = [];
                    %                 fibIndex = 1;
                    for iFiber = 1:numel(obj.Vertices)
                        Vectors(FiberIndices(iFiber):FiberIndices(iFiber+1)-1) = obj.Vertices(iFiber).Vectors;
                    end
                    FiberIndices(iFiber+1) = length(Vectors)+1;
            end
        end
     
    end
end

