function [track] = A_parseTTfile(file)

data = load(file,'-mat');
track = parse_tt(data.track);
T = reshape(data.trans_to_mni,4,4);

f = Fibers;
n = numel(track);
wb = waitbar(0,['Loading ',num2str(n), ' fibers']);

for iTrack = 1:n
    f.addFiber(SDK_transform3d(track{iTrack},T),iTrack);
    waitbar(iTrack/n,wb)
end
close(wb);
f.see

    function track = parse_tt(track)
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
        
        track = cell(1,length(pos));
        for i = 1:length(pos)
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
            track{i} = single(tt)/32;
        end
    end


end

