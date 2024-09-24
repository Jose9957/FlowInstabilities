%> @file SOURCES_MATLAB/SF_core_version.m
%> @brief Matlab function detecting freefem++ version
%>
%> Usage: version = SF_core_version()
%> @param[out] version: version of current freefem installation
%>
%> In case of error during version detection, a -1 value is returned
%>
%> @author Maxime Pigou
%> @version 1.0
%> @date 16/11/2018 Start writing version 1.0
function version = SF_core_version()
% -- Initialise version to -1 --
version = -1;

% -- Test current environment --
if ~SF_core_opts('test')
    SF_core_log('w', 'SF_core_version: current options do not form a consistent execution environment.');
    return;
end

% -- Execute erroneous FreeFem++ command and recover log --
logFileDir = SF_core_file('mktmpdir');
[~,logFilePath] = fileparts(SF_core_file('mktmpfile',logFileDir));
SF_core_freefem('', 'logpath', logFileDir, 'logfile', logFilePath);

fn = sprintf('%s/%s',logFileDir,logFilePath);
fh = SF_core_file('fopentextread',fn);
if fh==-1
    SF_core_log('w', 'SF_core_version: internal error. Could not open FreeFem log file.');
    return;
end

firstLine = fgetl(fh);
cellMatches = regexp(firstLine,'.*version[\s]*:[\s]*([0-9]+\.[0-9]*).*','tokens');
if numel(cellMatches) ~= 1
    SF_core_log('w', 'SF_core_version: error in reading file version. Contact author of SF_core_version with a copy of your full log (verbosity=6).');
    return;
end
version = sscanf(cellMatches{1}{1},'%f');
SF_core_log('n', sprintf('SF_core_version: FreeFem++ version detected: %s', cellMatches{1}{1}));

SF_core_syscommand('fclose',fh);
SF_core_file('rmtmpdir', logFileDir);

end