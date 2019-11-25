function scene = newScene(OPTIONALname)
    global arena 
        if not(isa(arena,'ArenaManager'))
            [arena,scene] = ArenaManager();
        else
        
            if nargin==1
        scene = arena.new(OPTIONALname);
            else
                scene = arena.new();
            end
        end


end