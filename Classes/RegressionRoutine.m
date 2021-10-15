classdef RegressionRoutine < handle
    
    properties
        Heatmap
        VoxelDataStack
        SamplingSetting
    end
    
     properties (Hidden)
        DirtyHistograms
        CleanHistograms
        DirtyregressModel
        LoadedMemory
        LOOCVpredictions
     end
    
    
    
    methods
         function obj = RegressionRoutine(HeatmapData,ImageDataStack,Samplingsetting)
            if nargin>0
                obj.Heatmap = HeatmapData;
            end
            if nargin>1
                obj.VoxelDataStack = ImageDataStack;
%             else
%                 obj.ImageDataStack=VoxelDataStack;
             end
            if nargin>2
                obj.SamplingSetting = SamplingSetting;
            else 
                obj.SamplingSetting='15bins';
            end
         end
         
         function obj=loadRegressionData(obj)

             if isempty(obj.Heatmap)
                 waitfor(msgbox('Find a file that serves as a heatmap'))
                 obj.Heatmap = Heatmap; %#ok 
                 obj.Heatmap.loadHeatmap();
             end
             if isempty(obj.VoxelDataStack.Voxels)
                
                answer = questdlg('do you have a recipe file?');
                switch answer
                    case 'Yes'
                        obj.VoxelDataStack.loadStudyDataFromRecipe()
                    case 'No'
                        obj.VoxelDataStack.loadDataFromFolder()
                end
             end
	      
         end
         

                     
        function  obj=execute(obj)
          setting=obj.SamplingSetting;
          f=figure;
          
            
           for n=1:numel(obj.VoxelDataStack.Weights)
               SubjectProfile=obj.VoxelDataStack.Voxels(:,:,:,n);
               
               
               switch setting
                   case'15bins'
                       if ~isempty(fieldnames(obj.Heatmap.Tmap))
                       bite=obj.Heatmap.Signedpmap.Voxels(and(SubjectProfile>0.5,obj.Heatmap.Tmap.Voxels~=0));
                       
                       %analyse bite
                       edges = -1:0.13333333333:1; % define the bins
                       h = histogram(bite,edges);
                       obj.DirtyHistograms(n,1:numel(edges)-1) = zscore(h.Values);
                       delete(h)
                       else
                           warning('Tmap not found, using Signedpmap only; precision may be affected by interpolation')
                           bite=obj.Heatmap.Signedpmap.Voxels(and(SubjectProfile>0.5,obj.Heatmap.Signedpmap.Voxels~=0));
                       
                       %analyse bite
                       edges = -1:0.13333333333:1; % define the bins
                       h = histogram(bite,edges);
                       obj.DirtyHistograms(n,1:numel(edges)-1) = zscore(h.Values);
                       delete(h)
                       end
                           
                           
                           
                           
                   case 'Dice'
                       
                   case 'Pearson'
                       
               end
              
           end
            close(f)
            obj.DirtyregressModel = fitlm(obj.DirtyHistograms,obj.VoxelDataStack.Weights); %Here it calculates the b (by fitting a linear model = multivariatelinearregression)
            figure;obj.DirtyregressModel.plot
        end
                       
           
           
                       
                       
        end
    end

        
    
    
    
    
    
%      LOO_heatmap = load(fullfile(obj.HeatmapFolder,[file,'.heatmap']),'-mat');
%                 LOO_signedP = LOO_heatmap.signedpmap;
%                 LOO_tmap = LOO_heatmap.tmap;
%                 LOO_VTA = obj.LoadedMemory.getVoxelDataAtPosition(iFilename);
%                 
%                 %take a bite
%                 sample = LOO_signedP.Voxels(and(LOO_VTA.Voxels>0.5,LOO_tmap~=0));
%                 
%                 %analyse bite
%                 edges = -1:0.13333333333:1; % define the bins
%                 h = histogram(sample,edges);
%                 obj.CleanHistograms(iFilename,1:numel(edges)-1) = zscore(h.Values);
%                 delete(h)
                
    
    
    



   

        
        
         
        
        
        
        
        
        
%         
%         function obj=regressionData(heatmap,imageData,Coefficient) %imagedata must be a VoxelDataStack
%            
%             if nargin>0
%                 heatmap=heatmap;
%             end
%             
%             if nargin>1
%                 imageData=imageData;
%             end
%             if nargin>2
%                 Coefficient=Coefficient
%             end
%         end
%        
%         function obj=loadRegressionData(obj,heatmap,Coefficient)
%             default='average';
%             
%             if nargin>0
%                 obj.imageData=VoxelDataStack;
%                 obj.imageData.loadStudyData();
%             end
%             if nargin<2
%                 waitfor(msgbox('Find a nii that serves as a heatmap'))
%                 [filename,foldername] = uigetfile('*.nii','Get heatmap file');
%                 mapfile = fullfile(foldername,filename);
%                 heatmap=VoxelData(mapfile);
%                 obj.heatmap=heatmap;
%             end
%             if nargin<3
%                Coefficient=default;
%             end
%             obj.similarityCoefficient=Coefficient;    
%             
%         end
%         
%         
%         
%     end
% end       
            
            
            
            
            
            
            
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
            

            
        