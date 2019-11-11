classdef PointCloud
    %POINTCLOUD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Vectors = Vector3D.empty;
        Weights = [];
    end
    
    methods
        function obj = PointCloud(vectors,weights)
            %POINTCLOUD Construct an instance of this class
            %   Detailed explanation goes here
            
            nVectors = numel(obj.Vectors); %initial condition
            switch class(vectors)
                case 'PointCloud' %unintended use
                    obj.Vectors = vectors.Vectors;
                    obj.Weights = vectors.Weights;
                otherwise
                    obj.Vectors = vectors;
            end
            
            
            
            addedVectors = numel(obj.Vectors)-nVectors;
            if exist('weights','var')
                if numel(weights)==addedVectors
                    obj.Weights(end+1:end+numel(weights),1) = weights;
                else
                    obj.Vectors(end-addedVectors+1:end) = []; %error: delete the added vectors
                    error('number of weights does not correspond with number of vectors')
                end
            else
                obj.Weights(nVectors+1:nVectors+addedVectors,1) = NaN;
            end
            
            
        end
        
        function obj = set.Vectors(obj,vectors)
            switch class(vectors)
                case 'Vector3D'
                    obj.Vectors = vectors;
                    
                case 'double'
                    obj.Vectors = Vector3D.empty;
                    if size(vectors,1)>1 && size(vectors,2)==3 %list
                        for i = 1:size(vectors,1)
                            obj.Vectors(end+1,1) = Vector3D(vectors(i,1),vectors(i,2),vectors(i,3));
                        end
                    elseif size(vectors,1)==1 && size(vectors,2)==3 %single
                        obj.Vectors(end+1,1) = Vector3D(vectors(1),vectors(2),vectors(3));
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
                multiplied(i) = obj.Vectors(i)*obj.Weights(i);
            end
            
            vectorOut = Vector3D(sum(multiplied.getArray)/sum(obj.Weights));
            
            
        end
    end
end

