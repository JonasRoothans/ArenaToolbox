function [B_,Tslice2vd,TfromslicetoLeadSpace] = A_obliquesliceParallelToElectrode(VD, e, angle)

    T = e.getTransformFromRoot;
    TtoIntrinsic = VD.getTransformToIntrinsic;
    
    vxl = 0.125;

    switch angle
        case 'cor'
            [x,y,z] = meshgrid(-25:vxl:25,0,-10:vxl:40);
            TfromslicetoLeadSpace = zeros(4);
            TfromslicetoLeadSpace(4,4) =1;
            TfromslicetoLeadSpace(1,1) = vxl;
            TfromslicetoLeadSpace(2,3) = vxl;
            TfromslicetoLeadSpace(4,1) = -25/vxl+1;
            TfromslicetoLeadSpace(4,3) = -10/vxl+1;
        case 'sag'
            [x,y,z] = meshgrid(0,-25:vxl:25,-10:vxl:40);
            TfromslicetoLeadSpace = zeros(4);
            TfromslicetoLeadSpace(4,4) =1;
            TfromslicetoLeadSpace(1,2) = vxl;
            TfromslicetoLeadSpace(2,3) = vxl;
            TfromslicetoLeadSpace(4,2) = -(75/vxl+2);
            TfromslicetoLeadSpace(4,3) = -10/vxl;
    end
    
    Tslice2vd = TfromslicetoLeadSpace*T;
    %transform to worldspace
    c_electrode = [x(:),y(:),z(:),ones(size(x(:),1),1)];
    c_intrinsic = c_electrode * T*TtoIntrinsic;
    

    
    B = interp3(VD.Voxels, c_intrinsic(:,1), c_intrinsic(:,2), c_intrinsic(:,3), 'linear', 0);
    B_ = reshape(B,size(squeeze(x)));
    
    %figure;imagesc(B_);
   
end