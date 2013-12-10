function DB = make_DB_name(db, type)
    if isdir(db)
        DB = fullfile(db, 'ImageSets', 'Action', sprintf('*_%s.txt', type));
        if isempty(dir(DB))
            error('Could not find any file of the form ''%s''.\n', DB);
        end
    else
        [db_root db_name] = fileparts(db);        
        DB = fullfile(db_root, sprintf('%s.%s.mat', db_name, type));
        if exist(DB, 'file') ~= 2
            error('''%s'' is not a directory and the file %s does not exist.\n', db, DB);
        end
    end
end