classdef A_Icp < SamplingMethod
    properties % uses the icp algorithm as provided by Jakob Wilm (2021). Iterative Closest Point (https://www.mathworks.com/matlabcentral/fileexchange/27804-iterative-closest-point), MATLAB Central File Exchange. Retrieved December 23, 2021.  
        RequiredHeatmaps = {'Signedpmap'} % use Kd_tree for speed optimization
        Description = 'checks for shape difference between both images. NaNs will be removed first'
        Output = [];
    end
    
    methods
        function [obj] = A_procrustes(Map, IndividualProfile)
            %---- keep this
            if nargin==0
                return
            end
            obj.mapIsOk(Map);  
            
            %---- customize code below
            
            %data
             map = Map.Signedpmap.Voxels;
             roi = IndividualProfile.Voxels;
             
           % get coordinates of positive values
           [row_profile,col_profile,v_profile]=find(roi);
           indices_profile=[row_profile,col_profile,v_profile];
           
           map(map<0)=0;
           
           [row_map,col_map,v_map]=find(map);
           indices_map=[row_map,col_map,v_map];
           
        
            %sample
            [TR, TT, ER, t]=icp(indices_map,indices_profile, 'Matching','kDtree');
            bite=mean(1-ER);
          
            
            
            obj.Output=bite;
        end
        
    end
    
    
end


