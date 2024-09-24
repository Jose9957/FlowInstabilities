function varargout = SF_core_opts(mode)
% Function reading the user option file if it exists in current path.
global sfoptsS sfopts

optsFileName = 'stabfem.opts';

switch mode
    case 'write'
        if ~SF_core_isopt('sfroot')
            SF_core_log('e', 'SF_core_opts/write: Option sfroot must be defined beforehand.');
            return;
        end
        optsFileName = [SF_core_getopt('sfroot') filesep 'SOURCES_MATLAB' filesep optsFileName];
        %[s,fHdl] = SF_core_syscommand('fopen', optsFileName, 'w', 'l', 'UTF-8'); % issue with octave and/or windowd
        fHdl = fopen(optsFileName, 'w');
        s = (fHdl==-1);
        if s==1
            SF_core_log('e', 'SF_core_opts/write: Could not open option file in writing mode.');
            return;
        end
        
        % Writing static option values
        for i=1:numel(sfoptsS)
            if sfoptsS(i).live; continue; end
            varName = sfoptsS(i).name;
            varValue = sfoptsS(i).value;
            fprintf(fHdl,'%s',stringFromVariable(varName,varValue));
        end
        
        % Closing file
        s = SF_core_syscommand('fclose', fHdl);
        if s==1
            SF_core_log('w', 'SF_core_opts/write: Option file could not be properly closed.');
            return;
        end
        
    case 'read'
        if exist(optsFileName, 'file')~=2
            SF_core_log('n', sprintf('SF_core_opts/read: %s could not be found', optsFileName));
            return;
        end
        
        fHdl = fopen(optsFileName);
        if fHdl==-1
            SF_core_log('e', 'SF_core_opts/read: Could not open option file in reading mode.');
            return;
        end
        fline = fgets(fHdl);
        while ~isequal(fline,-1)
            opt = strsplit(fline(1:end-1),':');
            varName = opt{1};
            if strcmp(opt{2},'char')
                varValue = opt{4};
            else
                varValue = cast(sscanf(opt{4},opt{3}),opt{2});
            end
            if ~SF_core_isopt(varName)
                SF_core_setopt(varName, varValue);
            end
            fline = fgets(fHdl);
        end
        
        s = SF_core_syscommand('fclose', fHdl);
        if s==1
            SF_core_log('w', 'SF_core_opts/read: Option file could not be properly closed.');
            return;
        end
        
    case 'reset'
        if ~isempty(sfopts)
            sfopts = [];
        end
        if ~isempty(sfoptsS)
            sfoptsS = [];
        end
       
    case 'test'
        %TODO: test
        SF_core_log('dd', 'SF_core_opts/test: Starting testing current options');
        varargout{1} = true;
        SF_core_log('dd', 'SF_core_opts/test: Option test ended successfully (TODO: implement actual tests!).');

        
    otherwise
        SF_core_log('w', 'SF_core_opts: invalid option managing mode. Expected read, write or test.');
end

    function str=stringFromVariable(name,var)
        switch class(var)
            case 'char'
                format = 's';
            case 'logical'
                format = 'u';
            case 'uint8'
                format = 'u';
            case 'double'
                format = 'f';
            otherwise
                str=[];
                return;
        end
        str = sprintf(['%s:%s:%%%s:%' format '\n'],name,class(var),format,var);  
    end
end
