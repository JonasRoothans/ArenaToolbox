classdef BiteAnalysis < handle 
    
    properties
        Map 
        IndividualProfile 
        SamplingMethod= @A_15bins;
    end
      properties(Hidden)
          SimilarityResult
      end
    
    methods
        function obj = BiteAnalysis(Map, IndividualProfile, SamplingMethod)
            
            if nargin>0
                obj.Map = Map; %by default to minimize memory consumption 
            end
            if nargin>1
                obj.IndividualProfile = IndividualProfile;
            end
            if nargin>2
                obj.SamplingMethod = SamplingMethod;
            end
        end
        
       
        function obj=takebite(obj, Mask, SamplingMethod) % Mask must be of the VoxelDataClass; like tmap for signedpmap 
            
            obj.SamplingMethod=SamplingMethod;
           
            if isempty(obj.Map) || isempty(obj.IndividualProfile)
                error('load first map and profile into class');
            end
                  
            if nargin<2
                Mask=0;
                warning(' no mask for map selected, if this is signedpmap, please load a tmap mask first');
            end
            
            
            
            
            obj.IndividualProfile.warpto(obj.Map);
            if nargin>1
                obj.SimilarityResult= feval(obj.SamplingMethod, obj.Map, obj.IndividualProfile,Mask);
            else
                obj.SimilarityResult= feval(obj.SamplingMethod, obj.Map, obj.IndividualProfile);
            end
            
            
%             switch SimilarityMethod
%                    case'15bins'
%                        if Mask
%                        bite=obj.Map.Voxels(and(obj.IndividualProfile.Voxels>0.5,Mask.Voxels~=0));
%                        
%                        else 
%                        bite=obj.Map.Voxels(and(obj.IndividualProfile.Voxels>0.5));
%                        warning(' no mask is applied, positive and negative values will be taken into account')
%                        end
%                        %analyse bite
%                        edges = -1:0.13333333333:1; % define the bins
%                        h = histogram(bite,edges);
%                        obj.SimilarityResult(n,1:numel(edges)-1) = zscore(h.Values);
%                        delete(h)
%                     
%                       
%                        
%                    case 'Dice'
%                        if Mask
%                        bite=dice(obj.Map.Voxels(Mask.Voxels~=0),obj.IndividualProfile.Voxels);
%                        
%                        else 
%                        bite=dice(obj.Map.Voxels,obj.IndividualProfile.Voxels);
%                        warning(' no mask is applied, positive and negative values will be taken into account')
%                        end
%                        obj.SimilarityResult=bite;
%                        
%                 case 'Pearson'
%                     
%                         if Mask
%                             bite=corr(obj.Map.Voxels(and(Mask.Voxels~=0,~isnan(obj.Map.Voxels))),obj.IndividualProfile.Voxels(~isnan(obj.IndividualProfile.Voxels)));
% 
%                         else
%                             bite=corr(obj.Map.Voxels(~isnan(obj.Map.Voxels)),obj.IndividualProfile.Voxels(~isnan(obj.IndividualProfile.Voxels)));
%                             warning(' no mask is applied, positive and negative values will be taken into account')
%                         end
%                         obj.SimilarityResult=bite;
%                         
%                 otherwise 
%                    
%                     error(' selected Similarity Metric not yet incorporated')
%             end
           
        end
    end
end
  
                    
                    
            
        

        
       
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
           