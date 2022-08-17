function [outputArg1,outputArg2] = BrainlabExtractor_makeLeadMarker(master,coords,outputdir)
%BRAINLABEXTRACTOR_MAKELEADMARKER Summary of this function goes here
%   Detailed explanation goes here

template = VoxelData(master);

if sum(sum(not(cellfun(@isempty,coords))))>=6
    
    
    coords = cellfun(@str2num,coords,'UniformOutput', false);
    
    template.zeros;
    bubble1 = makeBubble(template,coords(1,:),5,200);
    bubble1.savenii(fullfile(outputdir,'lead1_tip.nii'))
    
    template.zeros;
    bubble2 = makeBubble(template,coords(2,:),5,200);
    bubble2.savenii(fullfile(outputdir,'lead1_top.nii'))
    
   
    
end

if sum(~isempty(coords))==12
    template.zeros;
    bubble1 = makeBubble(template,coords(3,:),5,100);
    bubble1.savenii(fullfile(outputdir,'lead2_tip.nii'))
    
    template.zeros;
    bubble2 = makeBubble(template,coords(4,:),5,100);
    bubble2.savenii(fullfile(outputdir,'lead2_top.nii'))
end


    function vd = makeBubble(vd,center,diameter,value)
        [centerx,centery,centerz] = vd.R.worldToIntrinsic(center{1},center{2},center{3});
        center = Vector3D([centerx,centery,centerz]);
        vxl =  [vd.R.PixelExtentInWorldX, vd.R.PixelExtentInWorldY, vd.R.PixelExtentInWorldZ];
        if length(unique(vxl))>1
            error('Master needs to have square voxels')
        end
        diameter = diameter/vxl(1);
        
        xlow = floor(centerx-diameter);
        xhigh = ceil(centerx+diameter);
        ylow = floor(centery-diameter);
        yhigh = ceil(centery+diameter);
        zlow = floor(centerz-diameter);
        zhigh = ceil(centerz+diameter);
        
        for x = xlow:xhigh
            for y = ylow:yhigh
                for z = zlow:zhigh
                    d = center-Vector3D([x,y,z]);
                    if d.norm <= diameter
                        vd.Voxels(y,x,z) = value;
                    end
                end
            end
        end
        
        
    end




end

