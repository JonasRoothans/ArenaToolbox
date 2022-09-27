classdef NetworkModel < handle
    %each area from the segmentation gets its correlation to a clinical
    %value
       
    properties

        Tag string
        VoxelDataStack VoxelDataStack
        
        Areas 
        R
        Rabs
        p
        pabs
        Masks




    end

    methods
        function obj = NetworkModel(VoxelDataStack,Segmentation,Tag)
          
            obj.VoxelDataStack = VoxelDataStack;

            if ~isa(Segmentation,VoxelData)

               Segmentation = VoxelData(Segmentation) ;

            end


               obj.Masks =  cell(max(Segmentation.Voxels),1);
               for ii = 1:max(Segmentation.Voxels)

                   obj.Areas(ii,1)  = ii;
                   obj.Masks{ii,1} = Mask(Segmentation,ii);
                   obj.Masks{ii,1} = obj.Masks{ii,1}.warpto(VoxelDataStack);
                   obj.Masks{ii,1}  = obj.Masks{ii,1}.serialize;

               end

               if nargin > 2 

                   obj.Tag = Tag;
               end

               Nobs = length(VoxelDataStack.Voxels);

               X = zeros(ii,Nobs);

               for jj = 1:Nobs

                   for yy = 1:ii

                       fingerPrint = VoxelDataStack.Voxels(:,jj);

                       X(jj,yy) = sum(fingerPrint(obj.Masks{yy,1}),'all');
                       Xabs(jj,yy) = abs(sum(fingerPrint(obj.Masks{yy,1}),'all'));

                   end

                  
               end

               [obj.R,obj.p] = corr(X,VoxelDataStack.Weights','type','Spearman');
               [obj.Rabs,obj.pabs] = corr(Xabs,VoxelDataStack.Weights','type','Spearman');

        end

        function [predicted,R,p] = predict(obj,VoxelDataStack,pTrash,rTrash,baseonavarage) %if you want to
            %predict based on avarage, right whatever optional last input
            %arg..to base it on absolute value is a pure bullshit

            nObs = lenght(VoxelDataStack.Weights);

            tresholded = obj.p<pTrash;
            if nargin > 3

                Rtresholded=obj.R>rTrash;

                tresholded = tresholded&Rtresholded;

            end

            Masks = obj.Masks(tresholded);


            for ii = 1:nObs

                fingerprint=VoxelDataStack.Voxels(:,ii);

                for yy = 1:length(find(tresholded))

                    X(yy,ii) = sum(fingerprint(Masks{yy}),'all');

                end

            end

            if nargin>5

            predicted = sum(X,1)/length(find(tresholded));
            [R,p] = corr(predicted,VoxelDataStack.Weights,'type','Pearson');

            else

            
           predicted = sum(X,1);
           [R,p] = corr(predicted,VoxelDataStack.Weights,'type','Pearson');

            end

        end



    end

end



                    
                    





               













        

   