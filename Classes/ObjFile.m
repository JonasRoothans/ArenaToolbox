classdef ObjFile 
    %ObjFile contains Faces and Vertices. Can be initialised with *.obj
    
    properties
        raw
        Faces
        Vertices
         
    end
    
    properties (Hidden)
        description = '';
    end
   
    
    methods
        function obj = ObjFile(varargin)
            if nargin ==0
                return
            end
            if nargin==1
            if ischar(varargin{1})
                obj.raw= read_wobj(varargin{1});
                obj.Vertices = obj.raw.vertices;
                
                %find faces
                for iObjects = 1:numel(obj.raw.objects)
                    if strcmp(obj.raw.objects(iObjects).type,'f')
                        obj.Faces = obj.raw.objects(iObjects).data.vertices;
                    end 
                end
            end
            end
            if nargin==2
                if isnumeric(varargin{1})
                    obj.raw = nan;
                    obj.Faces = varargin{1};
                    obj.Vertices = varargin{2};
                end
            end
            
        end
        
        function obj = loadfile(obj,filename)
            if nargin==1
                [fn,pn] = uigetfile('*.obj');
                filename = fullfile(pn,fn);
            end
            
            obj = ObjFile(filename);
        end
        
        function obj = transform(obj,T)
            obj.Vertices = SDK_transform3d(obj.Vertices,T);
        end
        
       function varargout = see(obj,sceneobj)
            %Find or instantiate Arena
            
            global arena
            if nargin==1
                if isempty(arena)
                    evalin('base','startArena');
                    thisScene = arena.sceneselect(1);
                else %arena is running
                    thisScene = arena.sceneselect();
                end
            else %nargin==2
                thisScene = sceneobj;
            end
            
            if isempty(thisScene);return;end %user cancels
            thisActor = thisScene.newActor(obj);
            
            varargout{1} = thisActor;
            varargout{2} = thisScene;
            
            
        end
        
    end
end


