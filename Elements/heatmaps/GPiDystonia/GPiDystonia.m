classdef GPiDystonia < Heatmap
    %GPIDYSTONA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Tag = 'GPiDystonia'
        HeatmapModel
        b = [57.6598809951595;12.0664757620877;15.6438035692808;4.57530292424259;-3.13275389368958;-14.8795376587032;-14.5891044360106;0;16.9708673876284;12.6398172008286;8.23591228720219;13.9285582004609;4.62858440753228;-25.9956758412821;17.0527413996103;8.60861313752535];
        edges = -1:0.13333333333:1;
    end
    
    methods
        function obj = GPiDystonia()
            %constructor
        end
        
        function obj = load(obj)
            sweetspot  = load('Final_Bilateral_t_p_average.swtspt','-mat');
            sleft = sweetspot.sweetspot.left;
            obj.HeatmapModel.tmap = VoxelData(sleft,sweetspotArray(1).Data,sleft.imref);
            obj.HeatmapModel.pmap = VoxelData(sleft.sweetspotArray(2).Data,sleft.imref);
            obj.HeatmapModel.signed_p_map = VoxelData((1-obj.HeatmapModel.pmap.Voxels).*sign(obj.HeatmapModel.tmap.Voxels),sleft.imref);
        end
        
        function obj = sampleWithVTA(obj,VTA)
            if isempty(obj.HeatmapModel)
                obj.load()
            end
            
%            %check if mostly within model
%         allvoxels = heatmap.pmap(Excel(iSimilar).normalizedVTA.Voxels>0.5);
%         outofmodel = sum(allvoxels==0);
%         disp(strjoin({num2str(round(outofmodel/numel(allvoxels),3)),Excel(iSimilar).name,Excel(iSimilar).leadname,Excel(iSimilar).stimplanname},' '))
%         if outofmodel/numel(allvoxels)>0.3
%             disp(['adding to skiplist: ',num2str(similar)])
%             skiplist = [skiplist,similar];
%         end
%         
%         
%         totalSample = [totalSample;sample(:)];
%     end
%     h = histogram(totalSample,edges);
%     X = [1,zscore(h.Values)];  
%     y = X*b;
%     
%     for iSimilar = similar
%         Excel(iSimilar).prediction = y;
%     end
            
        end
    end
end

