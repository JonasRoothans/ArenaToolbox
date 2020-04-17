classdef Fibers < handle & matlab.mixin.Copyable
    %MESH Contains Faces and Vertices. Can be initialised with VoxelData
    
    properties
        Vertices = PointCloud.empty
        Indices = [];
        IncludeSeed = Mesh.empty
        Connectome
        Settings
    end
    
    properties (Hidden)
        ActorHandle;
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
            
        function obj = drawNewFiberInScene(obj,vertices,fiberindex,scene)
                        vizsettings = obj.ActorHandle.Visualisation.settings; %as set in arena
                        axes(scene.handles.axes)
                        n = numel(obj.Vertices)+1;
                        obj.Vertices(n) = PointCloud(vertices);
                        obj.Indices(n) = fiberindex;
                        
                        h = streamtube({vertices}, 0.5,[1 3]); 
                        if vizsettings.colorByDirection
                            color = PointCloud(abs(diff(vertices,1))).Vectors.unit;
                            color = [color;color(end,:)];

                            
                            colorArray = color.getArray;

                            streamFaceColors = [];
                            streamFaceColors(:,:,1) = repmat(colorArray(:,1),1, 3+1);
                            streamFaceColors(:,:,2) = repmat(colorArray(:,2),1, 3+1);
                            streamFaceColors(:,:,3) = repmat(colorArray(:,3),1, 3+1);
                        else
                            
                        CData = ones(size(h.XData,1),size(h.XData,2),3);
                        CData(:,:,1) = CData(:,:,1)*vizsettings.colorFace(1);
                        CData(:,:,2) = CData(:,:,2)*vizsettings.colorFace(2);
                        CData(:,:,3) = CData(:,:,3)*vizsettings.colorFace(3);
                            streamFaceColors = CData;
                        end
                        set(h, 'FaceColor', 'interp', 'CData', streamFaceColors, 'CDataMapping', 'direct', 'EdgeColor', 'none', 'FaceAlpha', vizsettings.faceOpacity/100);
                        %fv = surf2patch(h);
                        %obj.Handles(n) = h;
                        obj.ActorHandle.Visualisation.handle(n) = h;
                        drawnow
            
        end
        
        
        function obj = getFibersPassingThroughMesh(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            varargin = varargin{1}; %get rid of double nesting
            VoxelData= varargin{1};

              
        end
        
        function copyobj = duplicate(obj)
            copyobj = copy(obj);
        end
            

        function [thisActor,thisScene] = connectToScene(obj,thisScene)
            
             thisActor = thisScene.newActor(obj);
             obj.ActorHandle = thisActor;
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
        
            
     
    end
end

