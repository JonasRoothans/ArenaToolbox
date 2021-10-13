classdef RegressionRoutine < handle
    
    properties
        Heatmap
        VoxelDataStack
        Samplingsetting
    end
    
    methods
         function obj = RegressionRoutine(Heatmap,VoxelDataStack,Samplingsetting)
            if nargin>0
                obj.Heatmap = Heatmap;
            end
            if nargin>1
                obj.VoxelDataStack = VoxelDataStack;
            end
            if nargin>2
                obj.Samplingsetting = Samplingsetting;
            end
         end
         
        
        
         
        
        
        
        
        
        
        
        function obj=regressionData(heatmap,imageData,Coefficient) %imagedata must be a VoxelDataStack
           
            if nargin>0
                heatmap=heatmap;
            end
            
            if nargin>1
                imageData=imageData;
            end
            if nargin>2
                Coefficient=Coefficient
            end
        end
       
        function obj=loadRegressionData(obj,heatmap,Coefficient)
            default='average';
            
            if nargin>0
                obj.imageData=VoxelDataStack;
                obj.imageData.loadStudyData();
            end
            if nargin<2
                waitfor(msgbox('Find a nii that serves as a heatmap'))
                [filename,foldername] = uigetfile('*.nii','Get heatmap file');
                mapfile = fullfile(foldername,filename);
                heatmap=VoxelData(mapfile);
                obj.heatmap=heatmap;
            end
            if nargin<3
               Coefficient=default;
            end
            obj.similarityCoefficient=Coefficient;    
            
        end
        
        
        
    end
end       
            
            
            
            
            
            
            
%             default='average'
%             
%              if nargin>0
%                 waitfor(msgbox('Find a nii that serves as a heatmap'))
%                 [filename,foldername] = uigetfile('*.nii','Get heatmap file');
%                 mapfile = fullfile(foldername,filename);
%             end
%             
%             
%             if nargin<3
%                obj.similarityCoefficient=default
%             else
%                 obj.similarityCoefficient=Coefficient;
%             end
%             
%             if nargin>1
%               obj.imageData=VoxelDataStack;
%               obj.imageData.loadStudyData();
%             end
%         end
%         
%             
%     end   
%                 
%           
%     
% end
% %       function obj=dirty_regress(obj,way)
%             if nargin<1
%                 way='average'
%             end
%             if way='average'
%                 for ii=size(obj.
%                sample = regressionData.voxels(and(LOO_VTA.Voxels>0.5,LOO_tmap~=0));
            

            
        