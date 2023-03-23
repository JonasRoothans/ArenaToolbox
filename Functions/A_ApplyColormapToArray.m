function RGB = A_ApplyColormapToArray(inArray, minValue,maxValue)

if nargin==1
    minValue = min(inArray);
    maxValue = max(inArray);
end

cmap = colormap;
x = linspace(minValue,maxValue,length(cmap));
RGB = [interp1(x,cmap(:,1),inArray),...
    interp1(x,cmap(:,2),inArray),...
    interp1(x,cmap(:,3),inArray)];


end