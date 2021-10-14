classdef RegressionRoutine < handle
    
    properties
        HeatmapData
        ImageDataStack
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
                obj.HeatmapData = HeatmapData;
            end
            if nargin>1
                obj.ImageDataStack = ImageDataStack;
            else
                obj.ImageDataStack=VoxelDataStack;
            end
            if nargin>2
                obj.SamplingSetting = SamplingSetting;
            else 
                obj.SamplingSetting='15bins';
            end
         end
         
         function obj=loadRegressionData(obj)
             
             WarpStatus=0;
            
             if isempty(obj.HeatmapData)
                 waitfor(msgbox('Find a file that serves as a heatmap'))
                 [filename,foldername] = uigetfile('*.nii;*.swtspt;*.heatmap','Get heatmap file');
                 pattern=[".swtspt",".heatmap"];
                if contains(filename,'*.nii')
                     obj.HeatmapData.Signedpmap=VoxelData(fullfile(foldername,filename));
                elseif contains(filename,pattern)
                    
                    try
                     obj.HeatmapData=Heatmap;
                     obj.HeatmapData.loadHeatmap(fullfile(foldername,filename));
                     WarpStatus=1;
                    catch
                       warning('loading old swtspot file, data may be incompatible, loading default signedp')
                       hm=load(fullfile(foldername,filename),'-mat');
                       try
                           obj.HeatmapData.Signedpmap=hm.signedpmap;
                       catch
                           keyboard
                       end
                    end
                    if WarpStatus==0
                        waitfor(msgbox('Find a nii that serves as template space'))
                        [filename,foldername] = uigetfile('*.nii','Get template file');
                        if filename==0
                            return
                        end
                        braintemplate = fullfile(foldername,filename);
                        obj.HeatmapData.Signedmap=warpto(braintemplate);
                    end
                        
                       
                end
            
             end
             if isempty(obj.ImageDataStack.Voxels)
                
                answer = questdlg('do you have a recipe file?')
                switch answer
                    case 'Yes'
                        obj.ImageDataStack.loadStudyDataFromRecipe()
                    case 'No'
                        obj.ImageDataStack.loadDataFromFolder()
                end
             end
	      
         end
         

                     
        function  obj=execute(obj)
          templatemap=VoxelData;
          setting=obj.SamplingSetting;
          f=figure;
          
            
           for n=1:numel(obj.ImageDataStack.Weights)
               SubjectProfile=obj.ImageDataStack.Voxels(:,:,:,n);
               
               
               switch setting
                   case'15bins'
                       if ~isempty(fieldnames(obj.HeatmapData.Tmap));
                       bite=obj.HeatmapData.Signedpmap.Voxels(and(SubjectProfile>0.5,obj.HeatmapData.Tmap.Voxels~=0));
                       
                       %analyse bite
                       edges = -1:0.13333333333:1; % define the bins
                       h = histogram(bite,edges);
                       obj.DirtyHistograms(n,1:numel(edges)-1) = zscore(h.Values);
                       delete(h)
                       else
                           warning('Tmap not found, using Signedpmap only; precision may be affected by interpolation')
                           bite=obj.HeatmapData.Signedpmap.Voxels(and(SubjectProfile>0.5,obj.HeatmapData.Signedpmap.Voxels~=0));
                       
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
            obj.DirtyregressModel = fitlm(obj.DirtyHistograms,obj.ImageDataStack.Weights); %Here it calculates the b (by fitting a linear model = multivariatelinearregression)
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
            

            
        