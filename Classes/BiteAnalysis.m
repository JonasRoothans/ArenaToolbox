classdef BiteAnalysis < handle 
    % this class is as a buttler between the SamplingMethod and the
    % kitchen.
    % It can do last quality check after it leaves the kitchen
    
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
        
       
        function obj=takebite(obj) % Mask must be of the VoxelDataClass; like tmap for signedpmap 
            
            if isempty(obj.Map) || isempty(obj.IndividualProfile)
                error('load first map and profile into class');
            end
                  
            
            obj.IndividualProfile.warpto(obj.Map);
            obj.SimilarityResult= feval(obj.SamplingMethod, obj.Map, obj.IndividualProfile);

            
           

           
        end
    end
end
  
                    
                    
            
        

        
       
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
           