function write_input(file, feat)
    fid = fopen(file, 'w');
    fwrite(fid, 'BINDESC1CIRCLE  ', 'uint8');
 
    pointCount = size(feat,1);
    
    fwrite(fid, 5, 'uint32');
    fwrite(fid, 0, 'uint32');
    fwrite(fid, pointCount, 'uint32');
    fwrite(fid, 8, 'uint32');

    feat = reshape(feat',5*pointCount,1);
    fwrite(fid,feat,'float64');
    
    fclose(fid);

end

