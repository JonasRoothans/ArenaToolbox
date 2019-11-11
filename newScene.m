function scene = newScene()
    global arena 
        if not(isa(arena,'ArenaManager'))
            [arena,scene] = ArenaManager();
        else
        
        scene = arena.new();
        end


end