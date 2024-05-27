function [f] = A_parseTTfile(file, maxFibers)

if nargin==1
    maxFibers = [];
end

data = load(file,'-mat');
T = reshape(data.trans_to_mni,4,4);
f = parse_tt(data.track,T, maxFibers);


%f.see

    function f = parse_tt(track,T,maxFibers)
        f = Fibers;
        %source: https://groups.google.com/g/dsi-studio/c/3Y_lIRLWXTs?pli=1
        % Frank Yeh
        buf1 = uint8(track);
        buf2 = typecast(buf1,'int8');
        %buf2 = int8(track);
        pos = [];
        i = 1;
        while(i <= length(track))
            pos = [pos i];
            i = i + typecast(buf1(i:i+3),'uint32')+13;
        end
        n = length(pos);
        
        if n>maxFibers
            shuffle = randperm(n);
            indices = shuffle(1:maxFibers);
            n = maxFibers;
        else
            indices = 1:n;
        end
            
        counter = 0;
        if n>1000
            wb = waitbar(0,['Loading ',num2str(n/1000), 'k fibers']);
        else
            wb = waitbar(0,['Loading ',num2str(n), ' fibers']);
        end
        for i = indices
            counter = counter+1;
            waitbar(counter/n,wb)
            p = pos(i);
            size = typecast(buf1(p:p+3),'uint32')/3;

            %starting position
            x = typecast(buf1(p+4:p+7),'int32');
            y = typecast(buf1(p+8:p+11),'int32');
            z = typecast(buf1(p+12:p+15),'int32');
            tt = zeros(size,3);
            tt(1,:) = [x y z];
            p = p+16;
            for j = 2:size
                %difference
                x = x+int32(int8(buf2(p)));
                y = y+int32(int8(buf2(p+1)));
                z = z+int32(int8(buf2(p+2)));
                p = p+3;
                tt(j,:) = [x y z];
            end
            f.addFiber(SDK_transform3d(single(tt)/32,T),i);
        end
        close(wb);
    end


end

