%> @file SOURCES_MATLAB/SF_core_isopt.m
%> @brief Matlab function testing whether an option exists
%>
%> Usage: result = SF_core_isopt(optname)
%>
%> @author Maxime Pigou
%> @version 1.0
%> @date 02/07/2019 Start writing version 1.0
function result = SF_core_isopt(optname)
global sfoptsS
if isempty(sfoptsS)
    result = false;
else
    result = any(strcmp(optname, {sfoptsS(:).name}));
end
end