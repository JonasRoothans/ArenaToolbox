classdef Shape < handle & matlab.mixin.Copyable & ArenaActorRendering
    %PATCH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Faces
        Vertices
        Settings
        Source
    end
    
    methods
        function [obj,actor] = Shape(varargin)
           
                if nargin==0
                    return
                end
                if isa(varargin{1},'matlab.graphics.primitive.Patch')
                    obj.Faces = varargin{1}.Faces;
                    obj.Vertices = varargin{1}.Vertices;
                
                %if faces and vertices are given
                elseif length(varargin)==2
                        obj.Faces = varargin{1};
                        obj.Vertices = varargin{2};
                        obj.Source = [];
                        obj.Settings = [];
                        
                %if Shape is replacint the patch commmand (with optional scene as last argument)        
                elseif length(varargin)>2
                    if isa(varargin{end},'ArenaScene')
                         scene = varargin{end};
                         varargin(end) = [];
                    else
                        scene = [];
                    end
                    if numel(varargin)==3 %add color to go for 3D patch
                        varargin{end+1} = 'k';
                        
                    end
                    varargin{end+1} = 'visible';
                    varargin{end+1} = 'off';
                    p = patch(varargin{:});
                    obj.Faces = p.Faces;
                    obj.Vertices = p.Vertices;
                    if ~isempty(scene)
                        actor = obj.see(scene);
                    else
                        actor = obj.see;
                    end
                    
                    if not(or(strcmp(p.FaceColor,'interp'),sum(p.FaceColor)==0))
                        actor.changeSetting('colorFace',p.FaceColor,'colorEdge',p.EdgeColor,'faceOpacity',p.FaceAlpha*100,'edgeOpacity',p.EdgeAlpha*100)
                    end
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
            if not(isempty(inputname(1)))
                thisActor.changeName(inputname(1))
            elseif not(isempty(obj.Label))
                thisActor.changeName(obj.Label)
            
                
            end
        end
        
        function cog = getCOG(obj)
            try
                cog = PointCloud(obj.Vertices).getCOG;
            catch
                cog = Vector3D([nan nan nan]);
            end
        end 
    end
end

