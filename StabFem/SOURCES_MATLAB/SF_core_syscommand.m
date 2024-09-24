%> @file SOURCES_MATLAB/SF_core_syscommand.m
%> @brief Matlab wrapper for multiple OS basic commands
%>
%> Usage: [s,...] = SF_core_syscommand(cmd,...)
%> @param[in] cmd: name of the command
%> @param[out] s: status code of command execution
%>
%> Available commands:
%>  *which: locate executables in available path.
%>    [s,path] = SF_core_syscommand('which'or 'where', program_name);
%>    s=0 -> program found, path returned in unix format
%>    s=1 -> program not found, path empty
%>
%>  *cp: copy file from origin to destination
%>    s = SF_core_syscommand('cp' or 'copy', origin, destination);
%>    s=0 -> copy operation succeeded
%>    s=1 -> copy operation failed
%>
%>  *app: append file at the end of an existing file
%>    s = SF_core_syscommand('app' or 'append', origin, destination);
%>    s=0 -> copy operation succeeded
%>    s=1 -> copy operation failed
%>
%>  *mv: move file from origin to destination
%>    s = SF_core_syscommand('mv' or 'move', origin, destination);
%>    s=0 -> move operation succeeded
%>    s=1 -> move operation failed
%>
%>  *mkdir: create new folder
%>    s = SF_core_syscommand('mkdir', folderPath)
%>    s=0 -> Folder creation succeeded
%>    s=1 -> Folder creation failed
%>
%>  *rm: delete file
%>    s = SF_core_syscommand('rm', path)
%>    s=0 -> File correctly deleted
%>    s=1 -> File could not be deleted
%>
%>  *fopen: open file for ulterior writing
%>    [s,fhdl] = SF_core_syscommand('fopen', filename, mode)
%>    s=0 -> File correctly opened
%>    s=1 -> File could not be opened in expected mode
%>
%>  *fullfile: return a correctly formated absolute path
%>    [s,abspath] = SF_core_syscommand('fullfile', path)
%>   or
%>    [s,abspath] = SF_core_syscommand('fullfile', root, relpath)
%>   s=0 -> abspath correctly constructed
%>   s=1 -> Error in abspath construction
%>   Paths are expected in UNIX format.
%>   path may be absolute, or relative to current directory
%>   The root/relpath formulation returns the absolute path root/relpath.

function [status,varargout] = SF_core_syscommand(cmd,varargin)

if ~ischar(cmd)
    status=1;
    SF_core_log('e','SF_core_syscommand: unrecognized command.');
    return
end

try
    switch cmd
        case {'which' 'where'}
            name = varargin{1};
            if strcmp(SF_core_getopt('platform'),'pc')
                [s,t] = SF_core_system(sprintf('where %s',name));
            else
                [s,t] = SF_core_system(sprintf('which %s',name));
            end
            if s==0
                t(end) = [];
                SF_core_log('ddd',sprintf(['SF_core_syscommand/which:' ...
                    ' located command %s in: %s'],name, t));
                status = 0;
                varargout{1} = t;
                return;
            else
                SF_core_log('ddd',sprintf(['SF_core_syscommand/which:' ...
                    ' could not locate command %s'],name));
                status = 1;
                varargout{1} = [];
            end

        case {'cp' 'copy'}
            pathOrig = SF_core_path(varargin{1});
            pathDest = SF_core_path(varargin{2});
            if strcmp(rel2abs(pathOrig),rel2abs(pathDest))
                SF_core_log('ddd',sprintf(['SF_core_syscommand/cp:' ...
                    ' No need copying file %s onto itself.'],pathOrig));
                status = 0;
                return;
            end
            if strcmp(SF_core_getopt('platform'),'pc')
                [s,t] = SF_core_system(sprintf('copy %s %s',pathOrig,pathDest));
            else
                [s,t] = SF_core_system(sprintf('cp %s %s',pathOrig,pathDest));
            end
            if s==0
                SF_core_log('dd',sprintf(['SF_core_syscommand/cp:' ...
                    ' Successfully copied %s to %s'],pathOrig,pathDest));
                status = 0;
                return;
            else
                SF_core_log('e',sprintf(['SF_core_syscommand/cp:' ...
                    ' Error while copying %s to %s:\n%s'],pathOrig,pathDest,t));
                status = 1;
                return;
            end
            
        case {'mv' 'move'}
            pathOrig = SF_core_path(varargin{1});
            pathDest = SF_core_path(varargin{2});
            if strcmp(rel2abs(pathOrig),rel2abs(pathDest))
                SF_core_log('dd',sprintf(['SF_core_syscommand/mv:' ...
                    ' No need moving file %s onto itself.'],pathOrig));
                status = 0;
                return;
            end
            if strcmp(SF_core_getopt('platform'),'pc')
                [s,t] = SF_core_system(sprintf('move /y %s %s',pathOrig,pathDest));
            else
                [s,t] = SF_core_system(sprintf('mv %s %s',pathOrig,pathDest));
            end
            if s==0
                SF_core_log('dd',sprintf(['SF_core_syscommand/mv:' ...
                    ' Successfully moved %s to %s'],pathOrig,pathDest));
                status = 0;
                return;
            else
                SF_core_log('e',sprintf(['SF_core_syscommand/mv:' ...
                    ' Error while moving %s to %s:\n%s'],pathOrig,pathDest,t));
                status = 1;
                return;
            end
        
        case {'app','append'}
            pathOrig = SF_core_path(varargin{1});
            pathDest = SF_core_path(varargin{2});
            if strcmp(SF_core_getopt('platform'),'pc')
              SF_core_log('e','Append not available on windows systems !')
            else
              [s,~] = SF_core_system(['cat ' ,pathOrig, ' >> ', pathDest]);
               if s==0
                SF_core_log('dd','SF_core_syscommand/append successful');
                status = 0;
                return;
            else
                SF_core_log('e','SF_core_syscommand/append failled');
                status = 1;
                return;
            end
            end
    
        case 'mkdir'
            path = SF_core_path(varargin{1});
            if SF_core_file('existdir',path)
                SF_core_log('dd',sprintf(['SF_core_syscommand/mkdir:' ...
                    ' Folder %s already exists.'],path));
                status = 0;
                return;
            end
            % We do not force creation of parents through -p option as there
            % is no windows equivalent. Write StabFem such as the full arborescence exists.
            [s,t] = SF_core_system(sprintf('mkdir %s',path));
            if s==0
                SF_core_log('dd',sprintf(['SF_core_syscommand/mkdir:' ...
                    ' Folder %s successfully created.'],path));
                status = 0;
                return;
            else
                SF_core_log('e',sprintf(['SF_core_syscommand/mkdir:' ...
                    ' Folder %s could not be created: %s.'],path,t));
                status = 1;
                return;
            end
               
        case 'cleandir'  
           filename = varargin{1};
           if exist(filename,'dir')
            thedir = dir(filename);
            for i = 1:length(thedir)
                if (~thedir(i).isdir)
                    SF_core_syscommand('rm',[filename '/' thedir(i).name]);
                else
                    if ~strcmp(thedir(i).name(end),'.')  
                       SF_core_syscommand('rm',[filename '/' thedir(i).name]);
                    end
                end
            end
            %rmdir(filename,'s');
            end
            
        case {'rm' 'del'}
            path = SF_core_path(varargin{1});
            isFile = SF_core_file('existfile',path);
            if isFile
                isFolder = false;
            else
                isFolder = SF_core_file('existdir', path);
            end
            if ~isFile && ~isFolder
                SF_core_log('dd',sprintf(['SF_core_syscommand/rm:' ...
                    ' File or folder %s does not exist.'],path));
                status = 0;
                return;
            end
            if strcmp(SF_core_getopt('platform'),'pc')
                if isFile
                    [s,t] = SF_core_system(sprintf('del /q %s',path));
                else%if isFolder
                    [s,t] = SF_core_system(sprintf('rmdir /s /q %s',path));
                end
            else
                [s,t] = SF_core_system(sprintf('rm -R -f %s',path));
            end
            if s==0
                SF_core_log('dd',sprintf(['SF_core_syscommand/rm:' ...
                    ' %s successfully deleted.'],path));
                status = 0;
                return;
            else
                SF_core_log('w',sprintf(['SF_core_syscommand/rm:' ...
                    ' %s could not be deleted: %s.'],path,t));
                status = 1;
                return;
            end
            
        case 'fopen'
            filename = varargin{1};
            mode = varargin{2};
            if numel(varargin)>2
                opts = varargin(3:end);
            else
                opts = {};
            end
            if SF_core_getopt('isoctave')
               fid = fopen(filename,mode); %TO USE WITH OCTAVE
            else
                fid = fopen(filename,mode,opts{:}); %TO USE WITH MATLAB
            end
            
            if fid==-1
                status = 1;
                SF_core_log('e','SF_core_syscommand/fopen: File could not be opened.');
                varargout{1} = [];
                return;
            else
                status = 0;
                SF_core_log('dd', sprintf('SF_core_syscommand/fopen: File %s has been opened with %s permissions.', filename, mode));
                varargout{1} = fid;
                return;
            end
            
        case 'fclose'
            fHdl = varargin{1};
            fname = fopen(fHdl);
            status = fclose(fHdl);
            if status ~=0
                SF_core_log('w',sprintf('SF_core_syscommand/fclose: File %s could not be properly closed.',fname));
                status = 1;
            else
                SF_core_log('dd',sprintf('SF_core_syscommand/fclose: File %s has been closed.',fname));
            end
            
        case 'fullfile'
            if nargin==2
                relpath = varargin{1};
                if strcmp(relpath(1),'/')
                    root = '/';
                else
                    root = pwd();
                end
            elseif nargin==3
                root = varargin{1};
                relpath = varargin{2};
            else
                status = 1;
                varargout{1} = '';
                SF_core_log('e',sprintf('SF_core_syscommand/fullfile: Incorrect number of argument.'));
                return
            end
            root = SF_core_path(root,false,true);
            relpath = SF_core_path(relpath,false,true);
            varargout{1} = SF_core_path([root '/' relpath],false,true);
            status = 0;
            
        otherwise
            status=1;
        	SF_core_log('e','SF_core_syscommand: unrecognized command.');
            return;
    end
catch
    SF_core_log('e',sprintf('SF_core_syscommand: Error while calling command %s.',cmd));
    status = 1;
    return
end

%    function [s,t] = SF_core_system(cmd)
% this one is moved out

    function abspath = rel2abs(relpath)
        if strcmp(relpath(1),'/')
            abspath = relpath;
        else
            abspath = fullfile(pwd, relpath);
        end
        abspath = strrep(abspath, '/./', '/');
        abspath = strrep(abspath, '//', '/');
        % TODO: regexp to substitute:
        % /path1/path2/../text.txt -> /path1/text.txt
    end
end
