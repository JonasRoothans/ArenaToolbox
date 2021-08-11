classdef Connectome < handle
    %CONNECTOME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Data
        Path
        ID
    end
    
    properties (Hidden)
        fibers
        fiberids
        idcs_cumsum
    end
    
    methods
        function obj = Connectome()
            
        end
        
        function obj = linkToFile(obj,pathlistdata)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Path = pathlistdata.path;
            obj.ID = pathlistdata.id;
        end
        
        function obj = cache(obj)
            if not(isempty(obj.Data))
                disp('Loading complete');
            else
                disp(['Loading connectome ',obj.ID,'...'])
                obj.Data = load(obj.Path);
                disp('Loading complete');
                
                %preprocessing:
                obj.fibers = obj.Data.fibers(:,1:3);
                obj.fiberids = obj.Data.fibers(:,4);
                obj.idcs_cumsum = cumsum(obj.Data.idx);
            end
        end
        
        function [FibersObject] = getFibersConnectingMeshes(obj,seedmeshCell, n, scene, OPTIONALFibers)

            %organize data
            seed_fv_1.vertices = seedmeshCell{1}.Vertices;
            seed_fv_1.faces = seedmeshCell{1}.Faces;
            seed_fv_2.vertices = seedmeshCell{2}.Vertices;
            seed_fv_2.faces = seedmeshCell{2}.Faces;
            
            %If no Fibers-object is given, make a new one
            if nargin==4
                FibersObject = makeNewFibersObject(obj,seedmeshCell,scene);
                remove_these_from_candidates = []; %only useful when you don't want duplicates in an existing Fibers-object
            else
                FibersObject = OPTIONALFibers;
                remove_these_from_candidates = FibersObject.Indices;
            end
            
            
            %seed 1:
            [candidates_1,inNeighbourhood_1] = selectCandidates(obj,seed_fv_1,remove_these_from_candidates);
            
            %seed 2:
            [candidates_2,inNeighbourhood_2] = selectCandidates(obj,seed_fv_2,remove_these_from_candidates);
            
            %fibers/vertices in common
            candidates = intersect(candidates_1,candidates_2); %fibers
            vertices_not_too_far = or(inNeighbourhood_1,inNeighbourhood_2); %vertices

            disp(['now evaluating ',num2str(numel(candidates)),' fibers within range of both seeds.'])
            shuffle = randperm(length(candidates));
            counter = 0;
            for iFib = candidates(shuffle)'
                try
                    start = obj.idcs_cumsum(iFib-1)+1;
                catch
                    start = 1;
                end
                ending = obj.idcs_cumsum(iFib);
                
                %select vectors that might be inside seed
                tryThese = vertices_not_too_far(start:ending);
                thisFib = obj.fibers(start:ending,:);
                
                fiberPassingThrough_1 = any(seedmeshCell{1}.isInside(thisFib(tryThese,1:3)));
                if not(fiberPassingThrough_1)
                    continue
                end

                fiberPassingThrough_2 = any(seedmeshCell{2}.isInside(thisFib(tryThese,1:3)));
                fiberPassingThroughBoth = fiberPassingThrough_1 && fiberPassingThrough_2;
                if fiberPassingThroughBoth
                    FibersObject.addFiber(thisFib(:,1:3),iFib);
                    counter = counter + 1;
                    if counter == n
                        break
                    end
                end
            end
            
            
            disp(['now showing ',num2str(counter),' fibers.'])
        end
        
        %a different way.. but speed is comparable.
        
        
        
        function FibersObject = makeNewFibersObject(obj,seedmesh,scene)
                FibersObject = Fibers;
                FibersObject.Connectome = obj;
                FibersObject.IncludeSeed = seedmesh;
                FibersObject.connectToScene(scene);
        end
        
        function [FibersObject] = getFibersPassingThroughMesh(obj,seedmesh,n,scene,OPTIONALFibers)
            
            %redirect to other function
            if iscell(seedmesh)
                [FibersObject] = getFibersConnectingMeshes(obj,seedmesh, n, scene, OPTIONALFibers);
                return
            end
            
            
            seed_fv.vertices = seedmesh.Vertices;
            seed_fv.faces = seedmesh.Faces;
            
            %If no Fibers-object is given, make a new one
            if nargin==4
                FibersObject = makeNewFibersObject(obj,seedmesh,scene);
                remove_these_from_candidates = []; %only useful when you don't want duplicates in an existing Fibers-object
            else
                FibersObject = OPTIONALFibers;
                remove_these_from_candidates = FibersObject.Indices;
            end
            
            [candidates,inNeighbourhood] = selectCandidates(obj,seed_fv,remove_these_from_candidates);
           
            for iDuplicate = remove_these_from_candidates
                candidates(candidates==iDuplicate)= [];
            end
            
            
            disp(['now evaluating ',num2str(numel(candidates)),' fibers within range.'])
            shuffle = randperm(length(candidates));
            counter = 0;
            for iFib = candidates(shuffle)'
                
                %start and end
                try start = obj.idcs_cumsum(iFib-1)+1; catch; start = 1; end   
                ending = obj.idcs_cumsum(iFib);
                
                %select vectors that might be inside seed
                tryThese = inNeighbourhood(start:ending);
                thisFib = obj.fibers(start:ending,:);
                
                fiberPassingThrough = any(seedmesh.isInside(thisFib(tryThese,1:3)));
                if fiberPassingThrough
                    FibersObject.addFiber(thisFib(:,1:3),iFib);
                    counter = counter + 1;
                    if counter == n
                        break
                    end
                end
                
                
            end
        end
        
        function quickFibersPassingThroughMesh(obj,seedmesh,remove_these_from_candidates, n,FibersObject)
            
            
            %organize data
            home;disp('organizing connectome')
            fibers = obj.Data.fibers(:,1:3);
            fiberids = obj.Data.fibers(:,4);
            idcs_cumsum = cumsum(obj.Data.idx);
            seed_fv.vertices = seedmesh.Vertices;
            seed_fv.faces = seedmesh.Faces;
            
            %delete fiber dubplicates
            duplicates = ismember(fiberids,remove_these_from_candidates);
            fibers(duplicates) = [];
            fiberids(duplicates) = [];
            
            
            %generate meshgrid for seed
            disp('generating meshgrid')
            stepsize = 0.25;
            max_boundingbox = max(seed_fv.vertices);
            min_boundingbox = min(seed_fv.vertices);
            [xq,yq,zq] = meshgrid(min_boundingbox(1):stepsize:max_boundingbox(1),...
                min_boundingbox(2):stepsize:max_boundingbox(2),...
                min_boundingbox(3):stepsize:max_boundingbox(3));
            
            %sample seed volume to find which points fall within the seed. (=reference points)
            %(rationale: fibers that are near those points will likely also
            %fall within the seed)
            disp('sampling seed volume');
            fullsampling = [xq(:),yq(:),zq(:)];
            inSeed = inpolyhedron(seed_fv, fullsampling ,'flipnormals', true);
            referencePoints = fullsampling(inSeed,:);
            
            %make a rough preselection:
            disp('screening which fibers are in the neighbourhood..')
            maxD = max(pdist2(mean(seed_fv.vertices),seed_fv.vertices));
            [~,D] = knnsearch(mean(seed_fv.vertices),fibers(:,1:3));
            toofar = D>maxD;
            
            
            
            %finetune
            disp('Finetuning fibers')
            vertexInSeed = rangesearch(referencePoints,fibers(not(toofar),:),stepsize/2);
            subselection = fiberids(not(toofar));
            IDFiberInSeed = unique(subselection(cellfun(@isempty,vertexInSeed)));
            
            
            disp('Selecting all vertices in all fibers')
            shuffle = randperm(length(IDFiberInSeed));
            
            
            for i = 1:min([length(shuffle),n])
                FibersObject.addFiber(fibers(fiberids==fiberids(shuffle(i)),:),i);
            end
            
        end
        
         function [candidates,inNeighbourhood] = selectCandidates(obj,seed_fv,remove_these_from_candidates)
            disp('screening which fibers are in the neighbourhood..')
            maxD = max(pdist2(mean(seed_fv.vertices),seed_fv.vertices));
            [~,D] = knnsearch(mean(seed_fv.vertices),obj.fibers(:,1:3));
            toofar = D>maxD;
           
            inNeighbourhood = not(toofar);
            candidates = unique(obj.fiberids(inNeighbourhood));
            
            %filtering
            for iDuplicate = remove_these_from_candidates
                 candidates(candidates==iDuplicate)= [];
             end
            
        end
        
    end
    
    methods(Static)
       
    end
    
end


