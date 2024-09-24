%> @file SOURCES_MATLAB/SF_core_setopt.m
%> @brief Matlab function setting an option value
%>
%> Usage: SF_core_setopt(optname,optvalue, paramsname1, paramvalue1, ...)
%>
%> Options are placed in a global variable "sfoptsS" and saved in a
%> stabfem.opts file.
%>
%> Params may be:
%>  * live: true/false
%>     - If false, indicates that the option should be saved in a file and
%>       reloaded at the next start-up
%>  * settable: true/false
%>     - If true, an future call to setopt may be used to reset the option
%>       value
%>  * sanitizer: function_handle (or [])
%>     - If set, the sanitizer is applied to the option value before storing it.
%>       This includes the initial option declaration.
%>       The sanitizer must have one input and one output.
%>  * tester: function_handle (or [])
%>    - If set, the tester function is applied to the option value (after
%>      sanitization) to check whether the value makes sense for this option.
%>      The tester must have one input and one logical output.
%>  * watcher: function_handle (or [])
%>     - If set, the watcher function will be executed when the option is set.
%>       This includes the initial option declaration.
%>       The watcher must have the option name as input has no output.
%>       It is only available if settable is set to true.
%>
%> @author Maxime Pigou
%> @version 1.0
%> @date 02/07/2019 Start writing version 1.0
function SF_core_setopt(optname, optvalue, varargin)
global sfopts sfoptsS
% sfoptsS is a structure containing option associated parameters.
% sfopts is a structure directly containing option values, for legacy
% purposes.

%% FIX to prevent a bug in some cases (to be cleaned)
if strcmp('optname','workdir')
  SF_core_log('e',' option ''workdir'' is incorrect ; replace with ''ffdatadir'' ');
end
%% END FIX

if isempty(sfopts)
    sfopts=struct();
end
if isempty(sfoptsS)
    sfoptsS=struct('name', {}, 'value', {}, 'live', {}, 'settable', {}, 'sanitizer', {}, 'tester', {}, 'watcher', {});
end

% Read inputs
if ~isvarname(optname)
    SF_core_log('w', 'SF_core_setopt: incorrect option name');
    return
end

p = inputParser;
addParameter(p, 'live', false, @islogical);
addParameter(p, 'settable', true, @islogical);
addParameter(p, 'sanitizer', [], @testFctHandle);
addParameter(p, 'tester', [], @testFctHandle);
addParameter(p, 'watcher', [], @testFctHandle);
parse(p, varargin{:});

% Test whether option already exists and is settable
matchName = strcmp(optname,{sfoptsS(:).name});
existed = any(matchName);
if existed && ~sfoptsS(matchName).settable
    % Option already exists and is not settable
    SF_core_log('w', ['SF_core_setopt: option ',optname, ' already exists and is not settable anymore.']);
    return
end

% Load sanitizer, tester and watcher
if existed
    sanitizer = sfoptsS(matchName).sanitizer;
    tester = sfoptsS(matchName).tester;
else
    sanitizer = p.Results.sanitizer;
    tester = p.Results.tester;
    watcher = p.Results.watcher;
end

% Sanitize the input and test it
if ~isempty(sanitizer)
    try
        optvalue = feval(sanitizer, optvalue);
    catch
        SF_core_log('w', 'SF_core_setopt: option value triggered a sanitizer error.');
    end
end
if ~isempty(tester)
    if ~feval(tester, optvalue)
        SF_core_log('w', ['SF_core_setopt: This value was not accepted for the option ''' optname '''.']);
        return
    end
end

% Set the variable if required
if existed
    sfoptsS(matchName).value = optvalue;
    sfopts = cell2struct({sfoptsS(:).value},{sfoptsS(:).name},2);
    SF_core_log('dd', ['SF_core_setopt: option ' optname ' has been changed.']);
else
    sfoptsS(end+1) = struct('name', optname, 'value', [], ...
        'live', p.Results.live, 'settable', p.Results.settable, ...
        'sanitizer', sanitizer, 'tester', tester, 'watcher', watcher);
    sfoptsS(end) = setfield(sfoptsS(end),'value',optvalue); % in case it is a cell-array we need to do this
    sfopts = cell2struct({sfoptsS(:).value},{sfoptsS(:).name},2);
    SF_core_log('dd', ['SF_core_setopt: option ' optname ' has been added.']);
end

% Execute watcher if required
matchName = strcmp(optname,{sfoptsS(:).name});
if sfoptsS(matchName).settable && ~isempty(sfoptsS(matchName).watcher)
    feval(sfoptsS(matchName).watcher, optname);
end

end

% ===================
% == SUB-FUNCTIONS ==
% ===================
function r=testFctHandle(a)
r = isempty(a) || isa(a,'function_handle');
end