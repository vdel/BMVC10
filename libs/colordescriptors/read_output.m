function [feat descr] = read_output(file)
    fid = fopen(file, 'r');
    if(fid == -1)
        throw(MException('',['Cannot open the file ' file]));
    end
       
    header = fread(fid, 16, 'uint8=>char')';
    assert(strcmp(header(1:8),'BINDESC1'));
    assert(strcmp(header(9:16),'CIRCLE  ') || strcmp(header(9:16),'UNKNOWN '));
    
    header = fread(fid, 4, 'uint32')';
    elementsPerPoint = header(1);
    dimensionCount = header(2);
    pointCount = header(3);
    bytesPerElement = header(4);
    
    if(bytesPerElement == 8)
        prec = 'float64';
    else
        if(bytesPerElement == 4)
            prec = 'float32';
        else
            throw(MException('',sprintf('Bytes per element unknown: %d', bytesPerElement)));
        end
    end
    
    if(pointCount == 0)
        feat = [];
        descr = [];
    else
        feat = fread(fid,pointCount*elementsPerPoint,prec);
        feat = reshape(feat,elementsPerPoint,pointCount)';
        descr = fread(fid,pointCount*dimensionCount,prec);
        descr = reshape(descr,dimensionCount,pointCount)';
    end
    
    fclose(fid);
end

