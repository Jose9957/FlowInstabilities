%> @file SOURCES_MATLAB/SF_core_log.m
%> @brief Matlab function managing StabFem output messages.
%>
%> Usage: SF_core_log(level, message, enforce)
%> @param[in] level : message importance level ('d', 'n', 'w' or 'e')
%> @param[in] message : message string
%> @param[in] enforce : optional logical value, may enforce message display
%>
%> Message importance levels:
%>
%>    'e'  : error message, alerts the user on fatal events that prevent
%>           execution continuation
%>    'w'  : warning message, alerts the user on important events that do not
%>           prevent the execution continuation
%>    'n'  : notice message, indicates progress to user (entering/leaving script and main results)
%>    'nn' : notice messages + freefem outputs
%>    'nnn': advanced notice messages (+all previous levels)  
%>    'l'  : legacy warning (usually equivalent to 'nnn')
%>    'd'  : debug message, indicates actions that are performed by the code
%>    'dd' : advanced debug messages
%>    'ddd' : dd + freefem debugging (high verbosity)
%>
%> Message are displayed if "enforce" is set to "true" or if user defined
%> verbosity level exceeds message importance level.
%>
%> User verbosity levels:
%>  0           no message shown (NORMAL MODE IN AUTORUNS)
%>  1 | 'e'     error messages shown
%>  2 | 'w'     warning messages shown (+ error)
%>  3 | 'n'     notice messages shown (+ warning and error)
%>  4 | 'nn'    double notice shown (including FreeFem output ; NORMAL MODE IN SCRIPTS)
%>  5 | 'nnn | 'l'  triple notice (+ legacy messages)
%>  6 | 'd'     debug
%>  7 | 'dd'    double debug (advanced debug)
%>  8 | 'ddd'   triple debug (including full FreeFem error messages) 
%>
%> @author Maxime Pigou
%> @version 1.1
%> @date 25/10/2018 Start writing version 1.0
%> @date 04/04/2019 Adding new verbosity levels with David. Version 1.1.
function SF_core_log(level, message, enforce)

if nargin<2 || nargin>3
    SF_core_log('w', 'SF_core_log misused: invalid number of arguments.', true);
    return;
end
if nargin==2
    enforce = false;
end
enforce = logical(enforce);

if ~SF_core_isopt('verbosity')
    enforce = true;
else
    ulevel = SF_core_getopt('verbosity');
end

if enforce
    ulevel = 6;
end

if ~ischar(level)
    SF_core_log('w', 'SF_core_log misused: unexpected message level.', true);
    return;
end


try
level = lower(level);
switch level
    case 'ddd'
        fid = 1;
        nlevel = 8;
        prefix = 'DEBUG++ ';
    case 'dd'
        fid = 1;
        nlevel = 7;
        prefix = 'DEBUG+  ';
    case 'd'
        fid = 1;
        nlevel = 6;
        prefix = 'DEBUG   ';
    case 'nnn'
        fid = 1;
        nlevel = 5;
        prefix = 'NOTICE++';
    case 'l'
        fid = 1;
        nlevel = 5;
        prefix = 'LEGACY  ';
    case 'nn'
        fid = 1;
        nlevel = 4;
        prefix = 'NOTICE+ ';
    case 'n'
        fid = 1;
        nlevel = 3;
        prefix = 'NOTICE  ';
    case 'w'
        fid = 2;
        nlevel = 2;
        prefix = 'WARNING ';
    case 'e'
        fid = 2;
        nlevel = 1;
        prefix = 'ERROR   ';
    otherwise
        SF_core_log('w', ['SF_core_log misused: unexpected mesage level :',level], true);
        return;
end

if (ulevel>=nlevel)||(nlevel==1)
    if(ischar(message))
        fprintf(fid,'%s- %s\n',prefix,message);
    else
        disp(message)
    end
end

catch
    warning('PROBLEM WHEN USING SF_core_log')
end

if(nlevel==1)%&&ulevel>0)
    
    if SF_core_getopt('SF_PUBLISH')
        SF_core_log('w','An error is encountered while publishing script. Launching SF_Status for diagnostics');
        SF_Status;
    end
    error(message)
    %% David stop after an "error" except if SF_core_getopt('verbosity') = 0
end

end