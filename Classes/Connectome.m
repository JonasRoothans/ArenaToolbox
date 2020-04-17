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
        
        function [FibersObject] = getFibersPassingThroughMesh(obj,seedmesh,n,scene,OPTIONALFibers)
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

