%> @file SOURCES_MATLAB/SF_core_path.m
%> @brief Matlab function ensuring that correct path are used on pc platforms
%>
%> Usage: outputPath = SF_core_path(inputPath,isWindowsPath,forceLinuxOutput)
%> @param[in] inputPath : input path
%> @param[in] isWindowsPath : indicates whether inputPath is windows format
%> @param[in] forceUnixOutput : indicates whether to return unix format path
%> @param[out] validPath : path in expected format
%>
%> Usage cases:
%>  * outputPath = SF_core_path(inputPath,(false))
%>    - Assumes inputPath in Unix format, return current platform format
%>
%>  * outputPath = SF_core_path(inputPath,true,(false))
%>    - Expects inputPath in Windows format, return current platform format
%>
%>  * outputPath = SF_core_path(inputPath,true,true)
%>    - Expects inputPath in Windows format, return Unix format
%>
%> @author Maxime Pigou
%> @version 1.1
%> @date 25/10/2018 version 1.0
%> @date 16/11/2018 version 1.1: add new options and behaviours
function outputPath = SF_core_path(inputPath,isWindowsPath,forceUnixOutput)
% -- Define options --
if nargin<2
    isWindowsPath = false;
end
if nargin<3
    forceUnixOutput = false;
end

% -- Convert inputPath in unixPath --
unixPath = inputPath;
if isWindowsPath
    unixPath = strrep(unixPath, '\', '/');
    if strcmp(unixPath(2),':') %inputPath is a windows absolute path X:
        unixPath = ['/' unixPath]; %Add a leading slash to keep the path as absolute.
    end
end

% -- Clean the path --
lenghtEndClean = numel(unixPath)+1;
while true
    unixPath = strrep(unixPath, '/./', '/');
    unixPath = strrep(unixPath,newline,'');
    unixPath = strrep(unixPath, '//', '/');
    unixPath = regexprep(unixPath,'([-\w]+/\.\./?+)','');
    unixPath = regexprep(unixPath,'/$', '');
    unixPath = regexprep(unixPath,'/\.$', '');
    if numel(unixPath)==lenghtEndClean; break; end
    lenghtEndClean = numel(unixPath);
end

% -- If return Unix, stop here --
if forceUnixOutput
    outputPath = unixPath;
    throwLog(inputPath, outputPath);
    return;
end

% -- If return platform --
if ~SF_core_opts('test')
    SF_core_log('w', 'SF_core_path: No options currently defined, returning linux formated path.');
    outputPath = unixPath;
    throwLog(inputPath, outputPath);
    return;
end
outputPath = unixPath;
if strcmp(SF_core_getopt('platform'), 'pc')
    if strcmp(outputPath(1),'/')
        outputPath = outputPath(2:end);
    end
    outputPath = strrep(outputPath, '/', '\');
end
throwLog(inputPath, outputPath);
return;

    function throwLog(input,output)
        if strcmp(input,output)
            SF_core_log('dd', sprintf('SF_core_path: %s not converted', input));
        else
            SF_core_log('dd', sprintf('SF_core_path: %s converted into %s',...
                input, output));
        end
    end
end
