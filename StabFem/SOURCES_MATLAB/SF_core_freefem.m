%> @file SOURCES_MATLAB/SF_core_freefem.m
%> @brief Matlab function handling request to execute FreeFem++
%>
%> Usage: [status, msg] = SF_core_freefem(cmd, paramName, paramValue, ...)
%> @param[out] status: returned status code
%> @param[out] msg: output produced by system call
%>
%> Available parameters:
%>  * 'bin' (def: 'FreeFem++'): freefem executable name
%>  * 'parameters' (def: ''): string of parameters provided to FreeFem+++ (in pipe mode)
%>  * 'arguments' (def: '') string of arguments for the solver in getARGV mode
%>  * 'arg' (def: ''): arguments to give to the freefem executable
%>  * 'errormsg' (def: ''): error message threw when problem detected
%>  * 'logfile' (def: ''): name of a file in which the freefem output
%>                         should be redirected
%>  * 'logpath' (def: ''): path of the directory in which create the
%>                         logfile'Include'
%>  * 'prepipe' (def: ''): command redirected through a pipe to executable
%>     (LEGACY ; not recommended any more)
%>  * 'showerrormessage' (def. true)
%>  * 'continueonerror' (def. false) 
%>
%>  USAGE :
%>  1/ with parameters 
%>     SF_core_start('test.edp','parameters','1 2 3')
%>    will launch "echo 1 2 3 | FreeFem++-mpi test.edp"
%>  2/ with arguments
%>     SF_core_start('test.edp','arguments','-Re 100 -M 0.2')
%>    will launch "FreeFem++-mpi test.edp -Re 100 -M 0.2"
%> 
%>
%> FULL EXPLANATION :
%> Resulting system command:
%> $ echo "parameters" | (executable) (ffargs) (cmd) (arg) 
%> or
%> echo parameters | ffdir/bin sfopt.ffarg ffarg cmd
%> @author Maxime Pigou
%> @version 1.1
%> @date 12/11/2018 Start writing version 1.0
%> @date 20/11/2018 Switching to input parser treatment of arguments
function [status] = SF_core_freefem(cmd,varargin)
% Parse arguments
p = inputParser;
addParameter(p, 'ncores', 1, @isnumeric);
addParameter(p, 'bin', 'default', @ischar);
addParameter(p, 'parameters', '', @ischar);
addParameter(p, 'arguments', '', @ischar);
addParameter(p, 'prepipe', '', @ischar);
addParameter(p, 'arg', '', @ischar);
addParameter(p, 'errormsg', '', @ischar);
addParameter(p, 'logfile', '.FreeFem.log', @ischar);
addParameter(p, 'logpath', '', @ischar);
addParameter(p, 'continueonerror',false);
addParameter(p, 'showerrormessage',true);
addParameter(p, 'Include','');
addParameter(p, 'wait',true);
addParameter(p, 'nohupfile','nohup.out');
addParameter(p, 'datadir','');
addParameter(p, 'meshfilename','');
addParameter(p, 'initfilename','');

parse(p, varargin{:});
ncores = p.Results.ncores; % Number of cores (so far only HBN in parallel)

%if isempty(SF_core_getopt('ffroot'))
%    SF_core_log('w','FreeFem seems not available on your system !!!')
%end


if strcmp(p.Results.bin(1),'/')
  ffbin = p.Results.bin;  
elseif ~strcmp(p.Results.bin,'default')
  if ispc
    ffbin = p.Results.bin;
  else
     ffbin = ['"', SF_core_getopt('ffroot'), '/', p.Results.bin, '"'];
  end
else
  ffbin = [SF_core_getopt('freefemexecutable')];
end

% we should provide either 'parameter' or 'prepipe'
if(ncores==1)
    if ~isempty(p.Results.parameters)
        prepipe = [ 'echo ' p.Results.parameters];
    elseif ~isempty(p.Results.prepipe)
       prepipe = p.Results.prepipe;
    else 
        prepipe = '';
    end
else
    prepipe = '';
    ffbin = ['"', SF_core_getopt('ffroot'), '/ff-mpirun"'];
end

errormsg = p.Results.errormsg;
logfile = p.Results.logfile;
logpath = p.Results.logpath;
% appends the options to the default ones according to verbosity level
if(SF_core_getopt('verbosity')<8)
    if(ncores==1)
        args = [ SF_core_getopt('ffarg') p.Results.arg ];
    else
        args = [ '-np ', num2str(ncores), ' ', p.Results.arg ];
    end
else
    if(ncores==1)
        args = [ SF_core_getopt('ffargDEBUG') p.Results.arg ];
    else
        args = [ '-np ', num2str(ncores), ' ', p.Results.arg ];
    end
end


% Check options definition
if ~SF_core_opts('test')
    SF_core_log('e', 'SF_core_freefem: current options do not form a consistent execution environment.');
    status = 1;
    return;
end


% Check program (either in current directory or in ffdir common directory) 
if (exist(cmd,'file'))
    SF_core_log('d',[ 'SF_core_freefem : solver ' cmd '  found in current directoty']);
else
    for ffdir = SF_core_getopt('ffdir')
        if(exist([ffdir{1} '/' cmd],'file'))
           SF_core_log('d',[ 'SF_core_freefem : solver ' cmd '  found in ',ffdir{1},' directoty']);
        end
    end
end    
 

if ~isempty(prepipe)
    if(ncores==1)
        ffcmd = sprintf('%s | %s %s %s %s %s', prepipe, ffbin, args,  cmd, p.Results.arguments);
    else
        ffcmd = sprintf('%s | %s %s %s %s %s %s', prepipe, ffbin, args,  cmd, p.Results.arguments, SF_core_getopt('ffarg')); 
    end
else
    if(ncores==1)
        ffcmd = sprintf('%s %s %s %s %s', ffbin,  args, cmd, p.Results.arguments);
    else
        if(SF_core_getopt('verbosity')<8)
            ffcmd = sprintf('%s %s %s %s %s %s', ffbin,  args, cmd, p.Results.arguments, SF_core_getopt('ffarg'));
        else
            ffcmd = sprintf('%s %s %s %s %s %s %s', ffbin,  args, cmd, p.Results.arguments, SF_core_getopt('ffarg'), SF_core_getopt('ffargDEBUG'));
        end
    end
end



% -- Creation of the file freefem++.pref
fid = fopen('freefem++.pref','w');
fprintf(fid,'%s\n',['loadpath += "', SF_core_getopt('ffloaddir'), '"']);
ffdirs = SF_core_getopt('ffdir');
for ffdir = ffdirs
    fprintf(fid,'%s\n',['includepath += "', ffdir{1}, '"']);
end
ffincludedirs = SF_core_getopt('ffincludedir');
for ffincludedir = ffincludedirs
    fprintf(fid,'%s\n',['includepath += "', ffincludedir{1}, '"']);
end

fprintf(fid,'%s\n',['includepath += "', [ SF_core_getopt('ffdatadir') '/INCLUDE/'], '"']);



[~,thebin] = fileparts(ffbin);
if strcmp(SF_core_getopt('platform'),'mac')&&contains(SF_core_getopt('freefemexecutable'),'361')  %% && if version 3.61 
    % (bidouille Mac de David)
    SF_core_log('w', ' Bidouille pour FreeFem 3.61 sur mac David : writing paths in freefem++.pref  ');
    fprintf(fid,'%s\n','loadpath += "/usr/local/ff++/openmpi-2.1/lib/ff++/3.61-1/lib" ');
    fprintf(fid,'%s\n','loadpath += "/usr/local/ff++/openmpi-2.1/lib/ff++/3.61-1/lib/mpi" ');
    fprintf(fid,'%s\n','includepath += "/usr/local/ff++/openmpi-2.1/lib/ff++/3.61-1/idp/"');
end

fclose(fid);

% -- Creation of the file SF_AutoInclude.idp
 fid = fopen('SF_AutoInclude.idp','w');
 fprintf(fid,'%s\n','// This automatically generated file is to be included in the preamble of FF codes ');

 % ffdatadir is now written here
 if isempty(p.Results.datadir)
   datadir = SF_core_getopt('ffdatadir');
 else
   datadir = [SF_core_getopt('ffdatadir'),p.Results.datadir];
   if ~exist(datadir,'dir')
     SF_core_log('e',[' directory ',datadir,' does not exist']);
   end
 end
 fprintf(fid,'%s\n',['macro ffdatadir() "', datadir,'" //EOM']); 
 
 % themeshfilename is now written here
 if ~isempty(p.Results.meshfilename)
     fprintf(fid,'%s\n',['macro themeshfilename() "', p.Results.meshfilename,'" //EOM']);
 end
 
 % theinitfilename is now written here as well
 if ~isempty(p.Results.initfilename)
     fprintf(fid,'%s\n',['macro theinitfilename() "', p.Results.initfilename,'" //EOM']);
 end
 
 
 % Vhlist (replacing DATASTORAGEMODE) as well
 if ~isempty(SF_core_getopt('VhList'))
    Vhlist = SF_core_getopt('VhList');
    fprintf(fid,'%s\n',['macro VhList() "',Vhlist,'" //EOM '] );
end
 
if ~isempty(p.Results.Include)
    if ischar(p.Results.Include)
        SF_core_log('nn','Writing a line in  SF_AutoInclude.idp as specified' ); 
        fprintf(fid,'%s\n',p.Results.Include);
    elseif iscell(p.Results.Include)
        SF_core_log('nn','Writing a series of lines in SF_AutoInclude.idp as specified' );
        for i =1:length(p.Results.Include)
            fprintf(fid,'%s\n',p.Results.Include{i});
        end
    else
        SF_core_log('e','Failed to write lines in SF_AutoInclude.idp' );
    end
end
 fidlog = fopen('.stabfem_log.bash','a');
        if (fidlog>0)
            fprintf(fidlog, ['#  Here a file  SF_AutoInclude.idp has been created by driver SF_core_freefem \n'] );
            fclose(fidlog);
        end



% Next is legacy tricks for managing old versions
   if str2double(SF_core_getopt('ffmpiversion'))<4.3
      SF_core_log('nn','SLEPC implementation has changed ! tweaking file SF_AutoInclude.idp'); 
      fprintf(fid,'%s\n','IFMACRO(!SLEPCLEGACY)');
      fprintf(fid,'%s\n','    macro SLEPCLEGACY 1 //EOM');
      fprintf(fid,'%s\n\n','ENDIFMACRO');

   end
   if SF_core_getopt('ffversion')<4&&~isempty(strfind(ffbin,'mpi'))
      SF_core_log('w','old syntax for A''*B ! tweaking file SF_AutoInclude.idp'); 
      fprintf(fid,'%s\n','    macro OLDSHIFINVERT 1 //EOM');
  end
   
  fclose(fid);

  %pause(0.1); type('SF_AutoInclude.idp')
  

  
% -- Creation of the file SF_Custom.idp if does not exist
if ~exist('SF_Custom.idp','file')
  fid = fopen('SF_Custom.idp','w'); 
  fprintf(fid,'%s\n','// This file was automatically generated as no custom file was found ');
  fclose(fid);
end  
  
% -- Remove error/warning files
SF_core_syscommand('rm', [SF_core_getopt('ffdatadir') 'freefemwarning.txt']);
SF_core_syscommand('rm', [SF_core_getopt('ffdatadir') 'freefemerror.txt']);


%%%%%%%% LAUNCHING FREEFEM !    
if ~p.Results.wait
  if ispc
    SF_core_log('n','launching in detached mode (start)');
    ffcmd = ['start ',ffcmd, ' ']
  else
  SF_core_log('n','launching in detached mode (nohup)');
  ffcmd = ['nohup ',ffcmd, '> ',p.Results.nohupfile, ' &'];
  end
else
  SF_core_log('d','launching in interactive mode');
end

SF_core_log('d', 'SF_core_freefem: starting freefem execution');
SF_core_log('d', '===========================================');
SF_core_log('d', '$$                                         ');
SF_core_log('nn', '$$                                         ');
SF_core_log('nn', sprintf('$$ > %s', ffcmd));
SF_core_log('nn', '$$                                         ');

  
if(SF_core_getopt('verbosity')==4||SF_core_getopt('verbosity')>5)
    [s,t] = SF_core_system(ffcmd,'display'); % FreeFem outputs are displayed 'on the flight' 
else
    [s,t] = SF_core_system(ffcmd,'normal'); % FreeFem outputs are not displayed (but put in variable t) 
end

if ~p.Results.wait
  pause(0.1);
end

%%%%%%% POST-FREEFEM TASKS


if SF_core_getopt('verbosity')<2
    SF_core_syscommand('rm', 'freefem++.pref');
    SF_core_syscommand('rm', 'workdir.pref');
    SF_core_syscommand('rm', 'SF_AutoInclude.idp');
end

SF_core_log('d', '$$                                         ');
SF_core_log('d', '===========================================');
SF_core_log('d', 'SF_core_freefem: ending freefem execution');

 fidwarning = fopen([SF_core_getopt('ffdatadir') 'freefemwarning.txt']);
    if fidwarning>0
        ffwarning = fgets(fidwarning);
        while ~isequal(ffwarning,-1)
            if(SF_core_getopt('verbosity')==4)||(SF_core_getopt('verbosity')>5)
                SF_core_log('w',['WARNING IN FREEFEM : ', ffwarning]);
            end
            ffwarning = fgets(fidwarning);
        end
        fclose(fidwarning);
    end
    
    fiderror = fopen([SF_core_getopt('ffdatadir') 'freefemerror.txt']);
    if fiderror>0
        errormsg = fgets(fiderror);
        while ~isequal(errormsg,-1)
            if(SF_core_getopt('verbosity')==4)||(SF_core_getopt('verbosity')>5)
                SF_core_log('w',['WARNING IN FREEFEM : ', errormsg ]);
            end
            errormsg  = fgets(fiderror);
        end
        fclose(fiderror);
    end
if ~isempty(logfile)
    logRedirect = true;
    logFilePath = logfile;
    if ~isempty(logpath)
        if exist(logpath,'dir')~=7
            SF_core_log('w', 'SF_core_freefem: folder for log redirection does not exist, no redirection.');
            logRedirect = false;
            return;
        else
            logFilePath = SF_core_path(sprintf('%s/%s',logpath,logfile));
        end
    end
    if logRedirect
        fh = SF_core_file('fopentextwrite', logFilePath);
        if strcmpi(SF_core_getopt('platform'),'pc')
           % fix for windows to avoid issues with some special charachers 
           t = strrep(t,'\','\\');
        end
        fprintf(fh, t);
        fclose(fh);
    end
end
if s~=0 || (SF_core_getopt('isoctave') && (s~= 0 && s~=141 && s~=13))
    %if ~isempty(errormsg)
    %    SF_core_log('e', sprintf('SF_core_freefem: %s', errormsg));
    %end
    
   if SF_core_getopt('ErrorIfDiverge')
       we = 'e';
   else
       we = 'w';
   end
%   if isempty(errormsg)
    switch s
        case(1) 
            errormsg = 'Syntax error in your .edp program';
            errortype = 'e';
        case(2) 
            errormsg = 'Library not available';
            errortype = 'w';
        case(7)
            errormsg = 'Movemesh failed (or Attempt to read in a non-existing or invalid file)';
            errortype = we;
         case(8)
            errormsg = 'File not good in read array (or possibly division by zero)';
            errortype = 'e';    
        case(5)
            errormsg = 'Problem during mesh generation';
            errortype = 'e';
        case(139)
            errormsg = 'Segmentation fault';
            errortype = 'e';
        case(134)
            errormsg = '.edp file not found';
            errortype = 'e';    
        case(201)
            errormsg = ' Your Newton iteration did not converge';
            errortype = we;
            if errortype=='e'
                SF_core_log('w',' Divergence in Newton : Generating an error (default mode)');
                SF_core_log('w',' If you want to switch to debug mode and import the final iteration, use this :');
                SF_core_log('w','     " SF_core_setopt(''ErrorIfDiverge'',false) " ');
                SF_core_log('w','     ( NB your Newton solver has to be designed to  allow this mode )');
            end
        case(202)
            errormsg = ' Your Shift-invert iteration did not converge';
            errortype = we;
        case(203)
            errormsg = ' Your Time-stepping simulation diverged';
            errortype = 'w';    
        case(210)
            errormsg = ' AdaptMesh failed (probably the number of fields is too large or you are using a format not yet implemented). Please report to the authors !';
            errortype = we;
        otherwise
            errormsg = ' unrepertoriated Freefem++ error';
            errortype = we;
    end
%   else
%       errortype = 'w';
%   end

   
   if p.Results.continueonerror&&SF_core_getopt('isoctave')
       SF_core_log('nnn',' disabling error if diverge for octave (to be fixed)');
     errortype = 'w'; % for octave
   end
   if p.Results.showerrormessage
     SF_core_log(errortype, ['SF_core_freefem: Error while using FreeFem++  ; file = ', cmd,' ; error code = ',num2str(s) ,' : ' ,errormsg]);
     if ~isempty(t)&&SF_core_getopt('ErrorIfDiverge')
        t
     end
%     if ~SF_core_getopt('ErrorIfDiverge')
%         SF_Status;
%     end
   end
   status = s;
    % remarque : c'est un warning pas une erreur ! 
    % La generation d'une erreur (ou non) est faite  
    % dans la fonction qui appelle SF_core_freefem. les cas 201 et 202 ne
    % sont pas consideres comme des erreurs, le programme ne doit pas
    % s'arreter ! 
    % Par exemple si on fait une boucle et qu'on detecte une
    % divergence, on doit garder les r�sultats avant la divergence.
    % C'est le cas par exemple dans SF_Stability_LoopRe.m 
    
else
    status = 0;
end
end

