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
            addpath(mfilename('fullpath')); %adds the path including the sweetspotfiles
        end
        
        function obj = load(obj)
            sweetspot  = load('Final_Bilateral_t_p_average.swtspt','-mat');
            sleft = sweetspot.sweetspot.left;
            obj.HeatmapModel.tmap = VoxelData(sleft.sweetspotArray(1).Data,sleft.imref);
            obj.HeatmapModel.pmap = VoxelData(sleft.sweetspotArray(2).Data,sleft.imref);
            obj.HeatmapModel.signed_p_map = VoxelData((1-obj.HeatmapModel.pmap.Voxels).*sign(obj.HeatmapModel.tmap.Voxels),sleft.imref);
        end
        
        function prediction = predictionForVTAs(obj,VTAlist)
            sample = [];
            for iVTA = 1:numel(VTAlist)
                thisVTA = VTAlist(iVTA);
                sample = [sample,obj.sampleWithVTA(thisVTA)];
            end
            prediction = obj.predictForSample(sample);
            
        end
        
        function sample = sampleWithVTA(obj,VTA)
            %load the model
            if isempty(obj.HeatmapModel)
                obj.load()
            end
            
            %get the voxedata
            VTA_voxelData = VoxelData(VTA.Volume.Source.Voxels > 0.5,VTA.Volume.Source.R);
            
            %check the space and fix if it's not matching.
            if VTA.Space~=Space.Legacy
                VTA_voxelData = fixSpace(VTA.Space,VTA_voxelData);
            end
            
            %warp to heatmap space
            VTA_voxelData.warpto(obj.HeatmapModel);
            
            %sample map to see if it's overlapping enough with the model!
            allvoxels = obj.HeatmapModel.pmap(VTA_voxelData.Voxels>0.5);
            outofmodel = sum(allvoxels==0);
            if outofmodel/numel(allvoxels)>0.3
                warning(['VTA is partly outside the model! (',num2str(outofmodel/numel(allvoxels)*100),'%)'])
            end
            
            %sample those voxels where VTA and model both are.
            sample = obj.HeatmapModel.signed_p_map(and(...
                VTA_voxelData.Voxels>0.5,...
                obj.HeatmapModel.pmap>0));
        end
        
        function y = predictForSample(obj,sample)
            h = histogram(sample,obj.edges);
            X = [1,zscore(h.Values)];
            y = X*obj.b;
        end
    end
    
    methods (Static)
        function out = fixSpace(oldspace,voxeldata)
            switch oldspace
                case Space.MNI2009b
                    T = [-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1];
                    out = voxeldata.imwarp(T);
                case Space.Unknown
                case Space.PatientNative
            end
        end
    end
end

