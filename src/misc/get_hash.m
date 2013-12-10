function hash = get_hash(images)
    Ipaths = {images(:).path}';
    bndbox = cat(1,images(:).bndbox);

    for i = 1:length(Ipaths)
        [dir file] = fileparts(Ipaths{i});
        Ipaths{i} =  [file sprintf('%g %g %g %g',bndbox(:,1),bndbox(:,2),bndbox(:,3),bndbox(:,4))];
    end
    
    p = uint32(cat(2, Ipaths{:}));
    hash = uint32(1);
    prime = uint32(1967309);

    for i=1:length(p)
        hash = mod(hash*uint32(p(i)),prime);
    end
end

