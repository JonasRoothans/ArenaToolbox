classdef RegressedModel<handle
   

    properties
        NetworkModel NetworkModel

       
        Lm LinearModel
        LmAbs LinearModel
        pTrash (1,1)
        rTrash (1,1)
    end

    methods
        function obj = RegressedModel(NetworkModel,pTrash,rTrash)

            obj.NetworkModel = NetworkModel;
            obj.pTrash = pTrash;


            
            if nargin>2
                obj.rTrash = rTrash;
                error('not prepared yet and probably its shit anaway')

            end

            nObs = length(NetworkModel.VoxelsDataStack.Weights);
            PVec = 0.01:0.01:pTrash;
            start = repmat(pTrash,1,numel(PVec));
            Ps = start-PVec;
            Ps = [startwithp,Ps];

            for ii = 1:numel(Ps)

                tresholded = NetworkModel.p<Ps(ii);
                if nnz(tresholded)<(nObs+1)
                    break

                end

            end

            for yy = 1:numel(Ps)

                tresholdedA = NetworkModel.pabs<Ps(yy);
                tresholdedNA = NetworkModel.p<Ps(yy);

                if nnz(tresholdedNA,tresholdedA)<(nObs+1)
                    break

                end

            end


                
                














        end

        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end