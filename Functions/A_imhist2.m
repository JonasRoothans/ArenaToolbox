function f = A_imhist2(vd1,vd2)
%A_HISTOGRAM Summary of this function goes here
%   Detailed explanation goes here

v1 = vd1.Voxels(:);
v2 = vd2.warpto(vd1).Voxels(:);

v1(isnan(v1)) =0 ;
v2(isnan(v2)) =0 ;

min1 = min(v1);
max1 = max(v1);
min2 = min(v2);
max2 = max(v2);


v1 = (v1-min1)/(max1-min1);
v2 = (v2-min2)/(max2-min2);
v1 = round(v1*100)+1;
v2 = round(v2*100)+1;



histogram_ = zeros(101,101);

for i = 1:length(v1)
    histogram_(v2(i),v1(i))= histogram_(v2(i),v1(i))+1;
end


%-- find the best ticks:
[bestticks_x,bestticks_x_str] = findBestTicks(min1,max1,10);
xpos = (bestticks_x-min1)/(max1-min1)*100;

[bestticks_y,bestticks_y_str] = findBestTicks(min2,max2,10);
ypos = (bestticks_y-min2)/(max2-min2)*100;


f = figure;
set(f,'defaultTextInterpreter','none')
imagesc(log(histogram_))
colormap('gray')
set(gca,'YDir','normal')
xticks(xpos)
xticklabels(bestticks_x_str)
yticks(ypos)
yticklabels(bestticks_y_str)
try
xlabel(sprintf(vd1.Tag))
catch
    xlabel('[no name]')
end
try
ylabel(sprintf(vd2.Tag))
catch
     ylabel('[no name]')
end
end

function [bestticks,bestticks_str] = findBestTicks(min1,max1,steps)

xt = linspace(min1, max1,steps);
xt = xt-min(abs(xt));
N = floor( log10( max(abs(xt))))*-1;
xt = round(xt,N);
bestticks = unique(xt);
if numel(bestticks)==2
     bestticks = [bestticks(1), mean(bestticks),bestticks(2)];
end
bestticks_str = cellfun(@num2str,num2cell(bestticks),'UniformOutput',false);
end
