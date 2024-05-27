function [outputArg1,outputArg2] = A_loadDSItt(scene,filename)

%load header
data = load(filename,'-mat');
n = tt_length(data.track);

if n>10000
    quest = ['Your file contains ',num2str(n),' fibers! How do you want to proceed?'];
    title = 'Wow! Many fibers!';
    btn1 = 'Load all';
    btn2 = 'randomly select 10.000 fibers';
    defbtn = btn2;
    answer = questdlg(quest,title,btn1,btn2,defbtn);
    switch answer
        case btn1
            track = A_parseTTfile(filename,n);
        otherwise
            track = A_parseTTfile(filename,10000);
    end
else track = A_parseTTfile(filename,n);
end

track.see(scene)

%-------- FUNCTIONS
    function n = tt_length(track)
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

    end

end

