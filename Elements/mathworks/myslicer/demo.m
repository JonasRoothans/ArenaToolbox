
fprintf('\n\nMove the slices with your mouse pointer. If you use any of the standard tools that \ntakes control of the mouse (e.g. rotation), be sure to click on them again in order to \ndeactivate them before you try to move the slices again.\n\n')

f = figure;
camproj('perspective')
load mri;
T = [1 0 0 0;0 1 0 0;0 0 2.5 0];
h = myslicer(squeeze(D),T);
colormap gray;
axis off;

pause;

delete(h);
close(f);


%%
f = figure;
camproj('perspective')
h = myslicer(vd.Voxels,T)
colormap gray;
axis off;

pause;

delete(h);
close(f);
