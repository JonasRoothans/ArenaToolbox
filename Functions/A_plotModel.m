function [outputArg1,outputArg2] = A_plotModel(LM)
%A_PLOTMODEL Summary of this function goes here
%   Detailed explanation goes here

stepsX = 0.05;

Rsq = LM.Rsquared.Ordinary; RHO1 = Rsq;
pval = LM.Coefficients.pValue; PVAL1 = pval(2);%plotSlice(lmObj)
fprintf(2,'r^2 = %s \t p = %s \n', num2str(RHO1),num2str(PVAL1));

yData = LM.Variables.y;
xData = LM.Variables(:,[1:end-1]).Variables;

% % make the plot
%  first the scatter
figure; hold on
scatter(xData,yData,'ok','LineWidth',1.5);
% define boundaries for CI:
n1 = length(yData);
STATS1 = regstats(yData,xData,'linear','beta');% does not need a constant
GP1ind = xData; GP1dep = yData;
GP1xval = min(GP1ind)-stepsX:stepsX:max(GP1ind)+stepsX; 
beta1 = STATS1.beta;
Y1 = ones(size(GP1xval))*beta1(1) + beta1(2)*GP1xval;
SE_y_cond_x1 = sum((GP1dep - beta1(1)*ones(size(GP1dep))-beta1(2)*GP1ind).^2)/(n1-2);
SSX1 = (n1-1)*var(GP1ind);
SE_Y1 = SE_y_cond_x1*(ones(size(GP1xval))*(1/n1 + (mean(GP1ind)^2)/SSX1) + (GP1xval.^2 - 2*mean(GP1ind)*GP1xval)/SSX1);
Yoff1 = (2*finv(1-0.05,2,n1-2)*SE_Y1).^0.5;
top_int1 = Y1 + Yoff1;
bot_int1 = Y1 - Yoff1;
plot(GP1xval,Y1,'black','LineWidth',3);
% plot the CI as filled area
x_plot1 =[GP1xval, fliplr(GP1xval)];
y_plot2=[bot_int1, flipud(top_int1')'];
fill(x_plot1, y_plot2, 1,'facecolor', [0 1 1], 'edgecolor', 'none', 'facealpha', 0.4);
% give some format
ylabel(yDatName,'FontSize',14,'Interpreter','none')
xlabel(xDatName,'FontSize',14,'Interpreter','none');%,'Interpreter','latex'
% theString1 = sprintf('r^2 = %s \n p = %s', num2str(RHO1),num2str(PVAL1));
% l1 = legend(theString1,'Position','best');
% t = annotation('textbox'); t.String = theString1; t.Position = [0.588690482204159 0.732063497740125 0.29285713684346 0.20238094670432]; delete(l1); t.LineStyle = 'None'; t.Color = 'black';

% save figure
savefig(fullfile(opath,[FigName '.fig']))
saveas(gcf,fullfile(opath,[FigName '.jpg']),'jpeg')
hold off


disp('FINISHED.')
end
