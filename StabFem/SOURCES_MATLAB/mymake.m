function mymake(file)
% This is a platform-independent tool to create a new folder

global sfopts
if ~isempty(sfopts)
    SF_core_log('d', 'USE OF LEGACY FUNCTION DETECTED:');
    SF_core_log('d', sprintf('Please replace legacy command "mymake(''%s'')"',file));
    SF_core_log('d', sprintf('By new command "SF_core_syscommand(''mkdir'',''%s'')"',file));
    SF_core_syscommand('mkdir', file);
    return;
end

if (isunix || ismac)
    command = ['mkdir ', file];
    system(command);
end

if (ispc)
    c1 = ['mkdir '];
    c2 = [file];
    c2 = strrep(c2, '/', '\');
    command = [c1, c2];
    system(command);
end

end