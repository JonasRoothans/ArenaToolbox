% Test runs for meannormfilter_smooth_v01
close all, clear all

xyz = load('teapot_coord.txt');
tri = load('teapot_tri.txt');
tri(:,1) = [];tri = tri+1;
xyznoise = xyz+.25*rand(size(xyz));


figure, 
subplot 221,hold on
trisurf(tri,xyz(:,1),xyz(:,2),xyz(:,3))
axis equal, axis tight, view(20,20)
title('Original teapot')%xlabel('x'),ylabel('y'),zlabel('z')

subplot 222,hold on
trisurf(tri,xyznoise(:,1),xyznoise(:,2),xyznoise(:,3))
axis equal, axis tight, view(20,20)
title('Teapot with noise added to it')%xlabel('x'),ylabel('y'),zlabel('z')


out=meannorm_trismooth(xyznoise,tri);
out2=lpflow_trismooth(xyznoise,tri); 

subplot 223, hold on
trisurf(tri,out(:,1),out(:,2),out(:,3))
axis equal, axis tight, view(20,20)
xlabel('x'),ylabel('y'),zlabel('z')
title('Smoothed teapot using mean face normal code')

subplot 224, hold on
trisurf(tri,out2(:,1),out2(:,2),out2(:,3))
axis equal, axis tight, view(20,20)
xlabel('x'),ylabel('y'),zlabel('z')
title('Smoothed teapot using Laplace flow code')