%> @file SOURCES_MATLAB/SF_core_file.m
%> @brief Matlab function for simplifying interaction with files and paths
%>
%> Usage: [varargout] = SF_core_file(action, varargin)
%> @param[in] action: command associated with the desired action
%> @param[in] varargin: specific parameters for the desired action
%> @param[ou] varargout: output arguments 
%>
%> Note that following actions are case-insensitive.
%>
%> actions list:
%>  * res = SF_core_file('existDir', dirpath)
%>    > dirpath: path to a directory whose existence must be checked
%>    < res: boolean indicating directory existence
%>
%>  * res = SF_core_file('existFile', filepath)
%>    > filepath: path to a file whose existence must be checked
%>    < res: boolean indicating file existence
%>
%>  * tmpDirPath = SF_core_file('mkTmpDir')
%>    % Create a temporary folder and returns its path.
%>    % Empty path in case of error in folder creation.
%>    < tmpDirPath: path of temporary folder
%>
%>  * tmpFilePath = SF_core_file('mkTmpFile', (path))
%>    % Return the path to a non-existing temporary file
%>    > path: folder in which the file should be located
%>    < tmpFilePath: path to a non-existing file
%>    % if path is not provided, file will be located in system temporary
%>    % directory
%>
%>  * fh = SF_core_file('fopenTextWrite', filePath)
%>    % Opens a file in text write mode. Keeps the content if the file
%>    % already exists.
%>    < filePath: path to he file to be opened
%>    > fh: File handle (to use with fprintf, fwrite, fclose, ...)
%>    %Applies UTF-8 encoding with big-endian ordering
%>
%>  
%>
%> @author Maxime Pigou
%> @version 1.0
%> @date 16/11/2018 Start writing version 1.0
function varargout = SF_core_file(action, varargin)

if ~ischar(action)
    SF_core_log('e', 'SF_core_file: incorrection action.');
    varargout = cell(1,nargout);
    return;
end

try
switch lower(action)
    case 'existdir'
        dirpath = varargin{1};
        exists = exist(dirpath, 'dir')==7;
        if exists
            SF_core_log('dd', sprintf('SF_core_file/existdir: folder %s exists.', dirpath));
        else
            SF_core_log('dd', sprintf('SF_core_file/existdir: folder %s does not exist.', dirpath));
        end
        varargout{1} = exists;
        
    case 'existfile'
        filepath = varargin{1};
        exists = exist(filepath, 'file')==2;
        if exists
            SF_core_log('dd', sprintf('SF_core_file/existfile: file %s exists.', filepath));
        else
            SF_core_log('dd', sprintf('SF_core_file/existfile: file %s does not exist.', filepath));
        end
        varargout{1} = exists;
        
    case 'mktmpdir'
        tmpDirPath = SF_core_path(tempname,strcmp(SF_core_getopt('platform'),'pc'),true);
        if SF_core_syscommand('mkdir', tmpDirPath)~=0
            varargout{1} = '';
            SF_core_log('w', 'SF_core_file/mktmpdir: Error in temporary folder creation.')
        else
            varargout{1} = tmpDirPath;
        end
        return;
        
    case 'rmtmpdir'
        tmpDirPath = varargin{1};
        if ~SF_core_file('existdir', tmpDirPath)
            SF_core_log('n', sprintf('SF_core_file/rmtmpdir: Could not delete a non-existing folder: %s.',tmpDirPath));
        else
            SF_core_syscommand('rm',tmpDirPath);
        end

        
    case 'mktmpfile'
        if numel(varargin)==1
            tmpDirPath = varargin{1};
        else
            tmpDirPath = SF_core_file('mktmpdir');
        end
        if isempty(tmpDirPath)
            tmpDirPath = '.';
        end
        tmpFilePath = tempname(SF_core_path(tmpDirPath));
        tmpFilePath = SF_core_path(tmpFilePath,strcmp(SF_core_getopt('platform'),'pc'),true);
        SF_core_log('dd', sprintf('SF_core_file/mktmpfile: propose temporary file path: %s.', tmpFilePath));
        varargout{1} = tmpFilePath;
        return;
        
    case 'fopentextwrite'
        try
            [~,fh] = SF_core_syscommand('fopen',varargin{1},'a','b','UTF-8');
        catch
            fh = -1;
        end
        if fh==-1
            SF_core_log('w', 'SF_core_file/fopentextwrite: file could not be opened.');
        end
        SF_core_log('dd', sprintf('SF_core_file/fopentextwrite: file %s opened in write mode.', varargin{1}));
        varargout{1} = fh;
        return;
        
    case 'fopentextread'
        try
            [~,fh] = SF_core_syscommand('fopen',varargin{1},'r','b','UTF-8');
        catch
            fh = -1;
        end
        if fh==-1
            SF_core_log('w', 'SF_core_file/fopentextread: file could not be opened.');
        end
        SF_core_log('dd', sprintf('SF_core_file/fopentextwrite: file %s opened in read mode.', varargin{1}));
        varargout{1} = fh;
        return;
        
    otherwise
        SF_core_log('e', 'SF_core_file: unknown action.');
        varargout = cell(1,nargout);
        return; 
end
catch
    SF_core_log('e', 'SF_core_file: Unexpected error has been catched. Check arguments associated to your action.');
    varargout = cell(1,nargout);
    return;
end

end