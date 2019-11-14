classdef VectorCloud
    %POINTCLOUD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Base = Vector3D.empty;
        Direction = Vector3D.empty;
        Tertiary = Vector3D.empty;
        Weights = []
    end
    
    methods
        function obj = VectorCloud(base,direction, tertiary, weights)
            %POINTCLOUD Construct an instance of this class
            %   Detailed explanation goes here
            if nargin==0
                    return
            end
            switch class(base)
                case 'VectorCloud' %unintended use
                    obj.Base = base.Base;
                    obj.Direction = base.Direction;
                    obj.Tertiary = base.Tertiary;
                    obj.Weights = base.Weights;
                otherwise
                    
                    if not(numel(base)==numel(direction))
                        error('number of base vectors and direction vectors should be equal')
                    end
                    
                    obj.Base = base;
                    obj.Direction = direction;
                    if nargin==3
                        obj.Tertiary = tertiary;
                    end
                    if nargin==4
                        obj.Weights = weights;
                    end
            end
            
            
            
            
            
            
        end
        
        function obj = set.Base(obj,basevectors)
            switch class(basevectors)
                case 'Vector3D'
                    obj.Base = basevectors;
                    
                case 'double'
                    obj.Base = Vector3D.empty;
                    if size(basevectors,1)>1 && size(basevectors,2)==3 %list
                        for i = 1:size(basevectors,1)
                            obj.Base(end+1,1) = Vector3D(basevectors(i,1),basevectors(i,2),basevectors(i,3));
                        end
                    elseif size(basevectors,1)==1 && size(basevectors,2)==3 %single
                        obj.Base(end+1,1) = Vector3D(basevectors(1),basevectors(2),basevectors(3));
                    else
                        error('Vectors should be nx3')
                    end
            end
        end
        
          function obj = set.Direction(obj,vectors)
            switch class(vectors)
                case 'Vector3D'
                    obj.Direction = vectors.unit;
                    
                case 'double'
                    obj.Direction = Vector3D.empty;
                    if size(vectors,1)>1 && size(vectors,2)==3 %list
                        for i = 1:size(vectors,1)
                            obj.Direction(end+1,1) = Vector3D(vectors(i,1),vectors(i,2),vectors(i,3)).unit;
                        end
                    elseif size(vectors,1)==1 && size(vectors,2)==3 %single
                        obj.Direction(end+1,1) = Vector3D(vectors(1),vectors(2),vectors(3)).unit;
                    else
                        error('Vectors should be nx3')
                    end
            end
          end
        
                    function obj = set.Tertiary(obj,vectors)
            switch class(vectors)
                case 'Vector3D'
                    obj.Tertiary = vectors.unit;
                    
                case 'double'
                    obj.Tertiary = Vector3D.empty;
                    if size(vectors,1)>1 && size(vectors,2)==3 %list
                        for i = 1:size(vectors,1)
                            obj.Tertiary(end+1,1) = Vector3D(vectors(i,1),vectors(i,2),vectors(i,3)).unit;
                        end
                    elseif size(vectors,1)==1 && size(vectors,2)==3 %single
                        obj.Tertiary(end+1,1) = Vector3D(vectors(1),vectors(2),vectors(3)).unit;
                    else
                        error('Vectors should be nx3')
                    end
            end
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
            
            varargout{1} = thisScene;
            varargout{2} = thisActor;
            
        end
        
        
        function newPC = select(obj,idcs)
            if length(idcs)==length(obj.Weights)
                if not(islogical(idcs))
                    error('indexing requires logicals')
                end
            else
                if not(and(max(idcs)<=length(obj.Weights),min(idcs>0)))
                    error('indexing is out of bounds')
                end
            end
            newPC = PointCloud(obj.Vectors(idcs),obj.Weights(idcs));
            
            
        end
        
        %--- mathematical things
        function vectorOut = getWeightedAverage(obj)
            multiplied = Vector3D.empty;
            for i = 1:numel(obj.Weights)
                multiplied(i) = obj.Base(i)*obj.Weights(i);
            end
            
            vectorOut = Vector3D(sum(multiplied.getArray)/sum(obj.Weights));
            
            
        end
    end
end

