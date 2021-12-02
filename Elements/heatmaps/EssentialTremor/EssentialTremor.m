classdef EssentialTremor < HeatmapModelSupport & handle
    %GPIDYSTONA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Tag = 'Essential Tremor [beta]'
        HeatmapModel

    end
    
    methods
        function obj = CognitiveDecline()
            addpath(fileparts(mfilename('fullpath'))); %adds the path including the sweetspotfiles
        end
        
        function obj = load(obj)
            map = VoxelData;
            map.loadnii('cogdec_SE_vs_noSE_orig_fz_use_design_palm_vox_tstat_yeo1000_dil_precomputed_corr_R_Fz.nii')
            obj.HeatmapModel = map;
            
        end
        
%demo only
        
    end
end

