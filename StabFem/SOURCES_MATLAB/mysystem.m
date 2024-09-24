function status = mysystem(command, errormessage);

global ff ffdir ffdatadir sfdir verbosity

%%% OBSOLETE PROGRAM

%%% system command managements of StabFem.
%
% usage :
% status=mysystem(command,errormessage);
%   -> execute the command ; displays the errormessage if fails
%   special cases :
%    mysystem(command) -> will generate errormessage automatically
%    mysystem(command,'skip') -> will ignore the error and continue
%                       (useful for cp/mv/rm file manipulations)
%
%global parameter verbosity will control the verbosity :
% verbosity<10 : quiet mode (output from Freefem++ is not displayed unless error)
% verbosity=>10 : verbose mode (output from Freefem++ is displayed)
%
% This function is part of the StabFem project distributed under gnu
% licence, copyright D. Fabre (2017-2018).


if (nargin == 1)
    errormessage = ['mysystem Error while calling ', command];
end

global sfopts
if ~isempty(sfopts)
    SF_core_log('l', 'USE OF LEGACY FUNCTION DETECTED:');
    SF_core_log('l', 'Please replace legacy command "mysystem(...)"');
    SF_core_log('l', 'by new command "SF_core_freefem(...)". Note that arguments differ, read help documentation of SF_core_freefem.');
    
    % Split command by pipe symbol '|'
    splitpipe = strsplit(command,'|');
    args = {};
    if numel(splitpipe)==1
        postpipe = splitpipe{1};
    elseif numel(splitpipe)==2
        args = [args {'prepipe', strtrim(splitpipe{1})}];
        postpipe = splitpipe{2};
    elseif numel(splitpipe)>2
        SF_core_log('w', 'multiple pipe redirection detected in mysystem command, we may not autodetect how to use SF_core_version.');
        status = 1;
        return;
    end
    
    % Split post-pipe command by space symbol
    splitspace = strsplit(strtrim(postpipe),' ');
    ffbin = strtrim(splitspace{1});
    [~,ffbin_name,ffbin_ext] = fileparts(ffbin);
    args = [args {'bin', [ffbin_name ffbin_ext]}];
    
    cmd = strtrim(splitspace{end});
    
    if(numel(splitspace)>2)
        arg_list = cellfun(@(x)([x ' ']),splitspace(2:end-1),'UniformOutput',false);
        arg_list = strtrim([arg_list{:}]);
        args = [args {'arg' arg_list}];
    end
    
    % Send log to detail found arguments
    SF_core_log('d', sprintf('Parsed command: ''%s''. ', command));
    SF_core_log('d', sprintf('Calling SF_core_freefem(''%s'', args{:}) with following arguments: ', cmd));
    for i=1:numel(args)
        SF_core_log('d', sprintf('  * args{%u}: %s', i, args{i}));
    end
    

    SF_core_log('nnn',' How you should use SF_core_freefem :');
    SF_core_log('nnn',cmd);
    SF_core_log('nnn',args);
    % Perform call to freefem executable    
    status = SF_core_freefem(cmd, args{:});
    return;
end


if (verbosity < 10) % quiet mode
    [status, result] = SF_core_system(command);
    if (status ~= 0) && (status ~= 141) && (status ~= 13) && (strcmp(errormessage, 'skip') == 0)
        % NB if successful matlab retunrs 0, Octave returns 141, sometimes 13
        result
        if(verbosity<2)
            disp(errormessage);
        else
            error(errormessage);
        end
    end
else % verbose mode
    disp('$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$');
    disp('$$ ENTERING FREEFEM++ :')
    disp('$$ ');
    disp(['$$ > ', command]);
    disp('$$ ');
    [status] = SF_core_system(command);
    disp('$$ ');
    disp('$$ LEAVING FREEFEM++ :')
    disp('$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$');
    if (status ~= 0) && (status ~= 141) && (status ~= 13) && (strcmp(errormessage, 'skip') == 0)
        status
        error(errormessage);
    end
end
