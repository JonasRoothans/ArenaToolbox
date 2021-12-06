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
          Predictors
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
                
                %run at startup when all all input is provided
                obj = obj.takebite();
            end
            
            
        end
        
       
        function obj=takebite(obj) % Mask must be of the VoxelDataClass; like tmap for signedpmap 
            
            if isempty(obj.Map) || isempty(obj.IndividualProfile)
                error('load first map and profile into class');
            end
                  
            
            obj.IndividualProfile.warpto(obj.Map);
            method = feval(obj.SamplingMethod, obj.Map, obj.IndividualProfile);
            obj.Predictors= method.Output;
            
            if all(isnan(obj.Predictors))
                warning('All predictors are NaN')
            end

            
           

           
        end
    end
end
  
                    
                    
            
        

        
       
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
           