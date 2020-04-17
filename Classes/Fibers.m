classdef Fibers < handle & matlab.mixin.Copyable
    %MESH Contains Faces and Vertices. Can be initialised with VoxelData
    
    properties
        Vertices = PointCloud.empty
        Indices = [];
        Handles
        IncludeSeed = Mesh.empty
        Connectome
        Settings
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
            
        function obj = drawNewFiber(obj,vertices,fiberindex)
                        n = numel(obj.Vertices)+1;
                        obj.Vertices(n) = PointCloud(vertices);
                        obj.Indices(n) = fiberindex;
            
                        color = PointCloud(abs(diff(vertices,1))).Vectors.unit;
                        color = [color;color(end,:)];
                        
                        h = streamtube({vertices}, 0.5,[1 3]); 
                        colorArray = color.getArray;
                        
                        streamFaceColors = [];
                        streamFaceColors(:,:,1) = repmat(colorArray(:,1),1, 3+1);
                        streamFaceColors(:,:,2) = repmat(colorArray(:,2),1, 3+1);
                        streamFaceColors(:,:,3) = repmat(colorArray(:,3),1, 3+1);
                        set(h, 'FaceColor', 'interp', 'CData', streamFaceColors, 'CDataMapping', 'direct', 'EdgeColor', 'none', 'FaceAlpha', 0.2);
                        %fv = surf2patch(h);
                        obj.Handles(n) = h;
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

