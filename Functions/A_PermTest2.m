function [pValue, signedP] = A_PermTest2(sample1,sample2,p,discriminative_statistic,other)
%JR_2SAMPLEPERMUTATIONTEST Summary of this function goes here
%   Detailed explanation goes here

%%---------default values
if nargin==2
    p = 500000;
end
if nargin==5
    switch other
        case 'silent'
            verbose = 0;
        otherwise
            verbose = 1;
    end
else
    verbose = 1;
end

if nargin<=3
    discriminative_statistic = 'mean';
end

if isempty(discriminative_statistic) 
    discriminative_statistic = 'mean';
end
%-----


switch discriminative_statistic
    case 'mean'
        if verbose
            [h,ptest,ci,stats]=ttest2(sample2, sample1);
            disp (['p will approximate : ', num2str(ptest)])
            
        end
        test_statistic = abs(mean(sample1) - mean(sample2));
        p_sign = sign(mean(sample1) - mean(sample2));
    case 'correlation'
        	[test_statistic,ptest] = corr(sample1(:),sample2(:));
            disp (['p will approximate : ', num2str(ptest)])
            p_sign = sign(test_statistic);
    case 'linear regression'
        M= fitlm (sample1(:), sample2(:));
        ptest= M. Coefficients.pValue(2);
        test_statistic= M.Coefficients.tStat(2);
        disp ([ ' p will approximate :', num2str(ptest)])
        p_sign= sign(test_statistic);
        
    otherwise
        error(['Discriminative method "',discriminative_statistic,'" does not exist.'])
end






mixed = [sample1(:);sample2(:)];
tslist = zeros(1,p);
if verbose
    tic
end
for iP = 1:p
    if iP==100
        
        if verbose
            t = toc;
            disp(['this will take approx. ',num2str(t/100*p),' seconds or ',num2str(t/100*p/60),' minutes'])
        end
    end
    shuffle = mixed(randperm(length(mixed)));
    shuffle1 = sample1(randperm(length(sample1)));
    
    switch discriminative_statistic
        case 'mean'
            tslist(iP) = abs(mean(shuffle(1:numel(sample1))) - mean(shuffle(numel(sample1)+1:end)));
        case 'correlation'
            tslist(iP) = corr(shuffle1(:),sample2(:));
        case 'linear regression'
            L = fitlm( shuffle1(:), sample2(:));
            tslist(iP)= L.Coefficients.tStat(2);
            
    end
end

pValue = sum(tslist>=test_statistic) / p
signedP = (1-pValue) * p_sign
if verbose
    disp(['precision: ',num2str(1/p)])
    switch discriminative_statistic
        case 'mean'
            disp('if signedP is positive, then sample A is bigger than sample B')
        case 'correlation'
            disp('if signedP is positive, there is a positive correlation')
    end
    toc;
end
