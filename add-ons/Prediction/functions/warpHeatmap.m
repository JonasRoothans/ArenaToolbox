% in this script you can warp .swtspt heatmaps from legacs mni to mni
    
    Tfake2mni = [-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1];
    load('Final_Bilateral_t_p_average.swtsptKopie','-mat');
    tvaluel=sweetspot.left.sweetspotArray(1).Data;  
    pvaluel=sweetspot.left.sweetspotArray(2).Data;
    Tfake2mni=affine3d(round(Tfake2mni,8));
    [I_t_Predl,R_t_Predl]=imwarp(tvaluel,sweetspot.left.imref,Tfake2mni);
    [I_p_Predl,R_p_Predl]=imwarp(pvaluel,sweetspot.left.imref,Tfake2mni);
    a=isequal(R_p_Predl,R_t_Predl);
    sweetspot.left.imref=R_t_Predl;
    sweetspot.left.sweetspotArray(1).Data=I_t_Predl;  
    sweetspot.left.sweetspotArray(2).Data=I_p_Predl;
    path=uigetdir();
    file=fullfile(path,'BilateralSweetspot_t_p_average_realMNI.mat');
    save(file,'sweetspot');
    %% 
            v=vt;
            filename='BilateralSweetspot_t_p_average_realMNI_T_Kopie.nii'
            [x,y,z] = v.R.worldToIntrinsic(0,0,0);
            spacing = [v.R.PixelExtentInWorldX,v.R.PixelExtentInWorldY,v.R.PixelExtentInWorldZ];
            origin = [x y z];
            datatype = 16;%64;
            nii = make_nii(double(v.Voxels), spacing, origin, datatype);
            save_nii(nii,filename);
