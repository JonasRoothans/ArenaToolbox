function scene = getScene()
    global arena 
        if not(isa(arena,'ArenaManager'))
            [arena,scene] = ArenaManager();
        else
            scene = arena.sceneselect;
        end
end