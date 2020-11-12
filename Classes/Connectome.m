classdef Connectome < handle
    %CONNECTOME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Data
        Path
        ID
       
    end
    
    methods
        function obj = Connectome()
            %CONNECTOME Construct an instance of this class
            %   Detailed explanation goes here
            
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
            end
        end
        
        function [FibersObject] = getFibersConnectingMeshes(obj,seedmeshCell, n, scene, OPTIONALFibers)
            %run some input data tests
            % .. 
            % ..
            
            %organize data
            fibers = obj.Data.fibers(:,1:3);
            fiberids = obj.Data.fibers(:,4);
            idcs_cumsum = cumsum(obj.Data.idx);
            seed_fv_1.vertices = seedmeshCell{1}.Vertices;
            seed_fv_1.faces = seedmeshCell{1}.Faces;
            seed_fv_2.vertices = seedmeshCell{2}.Vertices;
            seed_fv_2.faces = seedmeshCell{2}.Faces;
            
            %If no Fibers-object is given, make a new one
            if nargin==4
                FibersObject = Fibers;
                FibersObject.Connectome = obj;
                FibersObject.IncludeSeed = seedmeshCell;
                FibersObject.connectToScene(scene);
                remove_these_from_candidates = []; %only useful when you don't want duplicates in an existing Fibers-object
            else
                FibersObject = OPTIONALFibers;
                remove_these_from_candidates = FibersObject.Indices;
            end
            
            disp('screening which fibers are in the neighbourhood..')
            
            %seed 1:
            maxD = max(pdist2(mean(seed_fv_1.vertices),seed_fv_1.vertices));
            [~,D] = knnsearch(mean(seed_fv_1.vertices),fibers(:,1:3));
            toofar_1 = D>maxD;
            candidates_1  = unique(fiberids(not(toofar_1)));
            
            %seed 2:
            maxD = max(pdist2(mean(seed_fv_2.vertices),seed_fv_2.vertices));
            [~,D] = knnsearch(mean(seed_fv_2.vertices),fibers(:,1:3));
            toofar_2 = D>maxD;
            candidates_2  = unique(fiberids(not(toofar_2)));
            
            %fibers/vertices in common
            candidates = intersect(candidates_1,candidates_2); %fibers
            vertices_not_too_far = or(not(toofar_1),not(toofar_2)); %vertices
            
            for iDuplicate = remove_these_from_candidates
                candidates(candidates==iDuplicate)= [];
            end
            
            %candidateVectors = find(not(toofar));
            
            
            disp(['now evaluating ',num2str(numel(candidates)),' fibers within range of both seeds.'])
                shuffle = randperm(length(candidates));
                counter = 0;
                for iFib = candidates(shuffle)'
                    try
                    start = idcs_cumsum(iFib-1)+1;
                    catch
                        start = 1;
                    end
                    ending = idcs_cumsum(iFib);
                    
                    %select vectors that might be inside seed
                    tryThese = vertices_not_too_far(start:ending);
                    thisFib = fibers(start:ending,:);
                    
                    fiberPassingThrough_1 = any(inpolyhedron(seed_fv_1, thisFib(tryThese,1:3),'flipnormals', true));
                    fiberPassingThrough_2 = any(inpolyhedron(seed_fv_2, thisFib(tryThese,1:3),'flipnormals', true));
                    fiberPassingThroughBoth = fiberPassingThrough_1 && fiberPassingThrough_2;
                    
                    if fiberPassingThroughBoth
                        disp(iFib)
                        
                        FibersObject.drawNewFiberInScene(thisFib(:,1:3),iFib,scene);
                        

                        counter = counter + 1;
                        if counter == n
                            
                            break
                        end
                    end
                end

            
            disp(['now showing ',num2str(counter),' fibers.'])
        end
        
        %quicker way to detect fibers in mesh.
        function fibervertices = quickFibersPassingThroughMesh(obj,seedmesh,scene)
            %organize data
            home;disp('organizing connectome')
            fibers = obj.Data.fibers(:,1:3);
            fiberids = obj.Data.fibers(:,4);
            idcs_cumsum = cumsum(obj.Data.idx);
            seed_fv.vertices = seedmesh.Vertices;
            seed_fv.faces = seedmesh.Faces;
            
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
            vertexInSeed = rangesearch(fibers(not(toofar),:),referencePoints,stepsize/2);
            subselection = fiberids(not(toofar));
            IDFiberInSeed = unique(subselection(cellfun(@isempty,vertexInSeed)));
            
            %TEMPORARY MAX OF 200 FIBERS
            if numel(IDFiberInSeed)>200
                IDFiberInSeed = IDFiberInSeed(1:200);
            end
            
            disp('Selecting all vertices in all fibers')
            vertexids = ismember(fiberids,IDFiberInSeed);
           	fibervertices = fibers(vertexids,:);

        end
        
        
        function [FibersObject] = getFibersPassingThroughMesh(obj,seedmesh,n,scene,OPTIONALFibers)
            
            %redirect
            if iscell(seedmesh) 
                [FibersObject] = getFibersConnectingMeshes(obj,seedmesh, n, scene, OPTIONALFibers);
                return
            end
            %run some input data tests
            % .. 
            % ..
            
            %organize data
            fibers = obj.Data.fibers(:,1:3);
            fiberids = obj.Data.fibers(:,4);
            idcs_cumsum = cumsum(obj.Data.idx);
            seed_fv.vertices = seedmesh.Vertices;
            seed_fv.faces = seedmesh.Faces;
            
            %If no Fibers-object is given, make a new one
            if nargin==4
                FibersObject = Fibers;
                FibersObject.Connectome = obj;
                FibersObject.IncludeSeed = seedmesh;
                FibersObject.connectToScene(scene);
                remove_these_from_candidates = []; %only useful when you don't want duplicates in an existing Fibers-object
            else
                FibersObject = OPTIONALFibers;
                remove_these_from_candidates = FibersObject.Indices;
            end
            
            disp('screening which fibers are in the neighbourhood..')
            maxD = max(pdist2(mean(seed_fv.vertices),seed_fv.vertices));
            [~,D] = knnsearch(mean(seed_fv.vertices),fibers(:,1:3));
            toofar = D>maxD;
            candidates  = unique(fiberids(not(toofar)));
            
            for iDuplicate = remove_these_from_candidates
                candidates(candidates==iDuplicate)= [];
            end
            
            candidateVectors = find(not(toofar));
            
            
            disp(['now evaluating ',num2str(numel(candidates)),' fibers within range.'])
                shuffle = randperm(length(candidates));
                counter = 0;
                for iFib = candidates(shuffle)'
                    try
                    start = idcs_cumsum(iFib-1)+1;
                    catch
                        start = 1;
                    end
                    ending = idcs_cumsum(iFib);
                    
                    %select vectors that might be inside seed
                    tryThese = not(toofar(start:ending));
                    thisFib = fibers(start:ending,:);
                    
                    fiberPassingThrough = any(inpolyhedron(seed_fv, thisFib(tryThese,1:3),'flipnormals', true));
                    if fiberPassingThrough
                        disp(iFib)
                        
                        FibersObject.drawNewFiberInScene(thisFib(:,1:3),iFib,scene);
                        

                        counter = counter + 1;
                        if counter == n
                            break
                        end
                    end
                
                   
                end
                
                
        end
        
        
    end
end

