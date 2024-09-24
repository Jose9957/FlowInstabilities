  function [s,t] = SF_core_system(cmd,option)
  %> This function is to be used instead of 'system'. 
  %> In addition to launchjng the command it will record everything in the log file "stabfem_log.bash" 
  %> 
  if (nargin<2)
      option = 'normal';
  end
        SF_core_log('dd', 'SF_core_syscommand: performing following system call:');
        SF_core_log('dd', ['$ ' cmd]);
        if strcmp(option,'display')
            s = system(cmd);
            t = '';
        else
            [s, t] = system(cmd);
        end
        if SF_core_getopt('StabfemIsOperational')
            fidlog = fopen('.stabfem_log.bash','a');
            if (fidlog>0)
                if strcmpi(SF_core_getopt('platform'),'pc')
                  % fix for windows to avoid issues with some special charachers 
                  cmd = strrep(cmd,'\','\\');
                end
                fprintf(fidlog, [cmd, '\n']);
                fclose(fidlog);
            end
        end
    end