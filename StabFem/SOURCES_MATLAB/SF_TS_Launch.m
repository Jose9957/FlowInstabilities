function folder = SF_TS_Launch(solver,varargin)
%>
%> StabFem generic driver for time-stepping computations
%>
%> USAGE :
%>    folder = SF_DNS(TimeStepper,
%>                    'Init',[initial field],
%>                    'Mesh',[mesh],
%>                    'Forcing',[forcing]
%>                    'Options',[list of parameters transmitted to solver and detected by getARGV ],
%>                    'ncores', [number of cores when using a parallel timestepper]
%>                    'wait', [true/false],
%>                    'samefolder',[true/false],
%>                    'folder',[number of folder | 'same' ],
%>                   )
%>
%> RESULTS :
%>    folder : name of the folder where the files will be done
%>
%> REMARK:   with option " 'wait',true " the driver will wait for the complete execution (default mode).
%>           with option " 'wait',false " the driver will launch the simulation as a background job
%>           which will keep on running  even if matlab/octave is closed (recommended for very long runs).
%>
%>
%> History : created june 2021 by DF to replace old driver SF_DNS.
%>
%> This is part of StabFem Project, D. Fabre, July 2017 -- present

p = inputParser;
addParameter(p, 'Init', '');
addParameter(p, 'Mesh', '');
addParameter(p, 'Forcing', '');
addParameter(p, 'Options', '');
addParameter(p, 'wait',true);
addParameter(p, 'samefolder',false);
addParameter(p, 'folder','');
addParameter(p, 'ncores',1);
parse(p, varargin{:});

%% Opening (or creating) the directory where data will be stored

ffdatadir = SF_core_getopt('ffdatadir');

if ~isempty(ffdatadir)&&~strcmp(ffdatadir,'./')
    if ~exist([ffdatadir,'TimeStepping'],'dir');
        SF_core_syscommand('mkdir',[ffdatadir,'TimeStepping']);
    end
    if ~exist([ffdatadir,'TimeStepping/.counter'],'file');
        fid = fopen([ffdatadir,'TimeStepping/.counter'],'w');
        fprintf(fid,'%i',0);
        fclose(fid);
    end
    
    if isempty(p.Results.folder)
        fid = fopen([ffdatadir,'TimeStepping/.counter'],'r');
        iruns = fscanf(fid,'%i');
        iruns = iruns+1;
        fclose(fid);
    else
        iruns = p.Results.folder;
    end
    
    if ~p.Results.samefolder
        workdir = ['TimeStepping/RUN',sprintf( '%06d', iruns ),'/'] ;
        truedestination = [ffdatadir,workdir];
        SF_core_log('n',['Results will be written in a new folder ', truedestination]);
        SF_core_syscommand('mkdir',truedestination);
        fid = fopen([ffdatadir,'TimeStepping/.counter'],'w');
        fprintf(fid,'%i',iruns);
        fclose(fid);
    
        fidlog = fopen('.stabfem_log.bash','a');
        if (fidlog>0)
            fprintf(fidlog, ['echo ',num2str(iruns), ' > ',ffdatadir,'TimeStepping/.counter \n']);
            fclose(fidlog);
        end
     
        
        
    elseif  contains(p.Results.Init.filename,'TimeStepping/RUN')
        
        truedestination = [fileparts(p.Results.Init.filename),'/'];
        workdir = truedestination(length(ffdatadir):end);
        if workdir(1)=='/'
            workdir = workdir(2:end);
        end
        SF_core_log('n',['Results will be written in the previously created folder ', truedestination]);
        
    else
        
        SF_core_log('e',' Using option ''samefolder'' works only if the init field is a snapshot from a previous simulation, which is apparently not the case');
        
    end
    
    if ~exist(truedestination,'dir')
        SF_core_log('w',[' Folder ', truedestination, ' not found : creating it !']);
    end
    
else
    SF_core_log('w',' DataBase management disabled ; some advanced functionalities may not work ');
    truedestination = './';
    workdir = './';
     thedir = dir('./');
            for i = 1:length(thedir)
                if contains(thedir(i).name,'.txt')||contains(thedir(i).name,'.ff2m')
                  SF_core_syscommand('rm',thedir(i).name);
                end
            end
end


%% Positioning mesh file and init file

startfield = p.Results.Init;
if ~isempty(startfield)
    SF_core_log('n', ['FUNCTION SF_DNS : starting from a specified initial condition']);
    initfilename = startfield.filename;
    SFcore_MoveDataFiles(initfilename,[workdir,'/Init.txt'],'cp');
    if isfield(startfield,'meshfilename')
        meshfilename = startfield.meshfilename;
        SFcore_MoveDataFiles(meshfilename,[workdir,'/mesh.msh'],'cp');
    else
        meshfilename = '';
        SF_core_log('w','no meshfilename specified in initial condition !');
    end
    
    % positioning initial condition file
    %switch lower(startfield.datatype)
    %    case {'baseflow','meanflow','addition'}
    %
    %        SF_core_log('n', ['FUNCTION SF_TS_Launch : starting from BF / MF (reset it = 0)']);
    %mycp(startfield.filename, [ffdatadir, 'dnsfield_start.txt']);
    %            SFcore_MoveDataFiles(startfield.filename,[workdir, 'snapshot_init.txt'],'cp');
    %            meshname = startfield.Mesh.filename;
    %    case {'dnsfield','snapshot'}
    %       %rep = startfield.it;
    %       SF_core_log('n', ['FUNCTION SF_DNS : starting from previous DNS result with it = ', num2str(rep)]);
    %       meshname = startfield.filename;
    %       SFcore_MoveDataFiles(meshname,['snapshot_init.txt'],'cp');
    %  otherwise
    %    SF_core_log('e', [' Init field of type unrecognized : ', startfield.datatype]);
    
    %end
    
elseif ~isempty(p.Results.Mesh)
    SF_core_log('n', ['FUNCTION SF_TS_Launch : starting with mesh, no init cond (default one defined in the solver will be used) ']);
    meshfilename = p.Results.Mesh.filename;
    initfilename = '';
    SFcore_MoveDataFiles(p.Results.Mesh.filename,[workdir,'mesh.msh'],'cp');
    
else
    SF_core_log('w', ['FUNCTION SF_TS_Launch : normally you should specify either a mesh  (''mesh'') or a initial condition  (''Init'') ! ']);
    meshfilename = '';
    initfilename = '';
end

%% Assembling 'options' as a string
folder = truedestination;
ffargument = SF_options2str(p.Results.Options); % transforms into a string
if ~isempty(startfield)
    if ~isfield(startfield,'it')
        startfield.it = 0;
    end
    if ~isfield(startfield,'t')
        startfield.t = 0;
    end
    ffargument = [ffargument, ' -i0 ',num2str(startfield.it), ' -t0 ',num2str(startfield.t)];
end


%% Creating (or appending) log file

if ~exist([truedestination,'/Simulation.log'])||strcmp(SF_core_getopt('ffdatadir'),'./')
    fid = fopen([truedestination,'/Simulation.log'],'w');
    fprintf(fid,'%s\n',[' Time-stepping simulation started ',datestr(now)]);
else
    fid = fopen([truedestination,'/Simulation.log'],'a');
    fprintf(fid,'\n');
    fprintf(fid,'%s\n',[' Time-stepping simulation RESTARTED ',datestr(now)]);
end
fprintf(fid,'%s\n', [' Solver                      : ',solver]);
fprintf(fid,'%s\n', [' Mesh file name              : ',meshfilename]);
fprintf(fid,'%s\n', [' Initial condition file name : ',initfilename]);
fprintf(fid,'%s\n', [' Argument string             : ',ffargument]);
fclose(fid);
        fidlog = fopen('.stabfem_log.bash','a');
        if (fidlog>0)
            fprintf(fidlog, ['# here a file ',truedestination,'/Simulation.log has been created  \n']);
            fclose(fidlog);
        end


if ~isempty(meshfilename)
    fid = fopen([truedestination,'/.meshfilename'],'w');
    fprintf(fid,'%s\n', meshfilename);
    fclose(fid);
end

SF_core_setopt('ErrorIfDiverge',false); % Legacy : this option is to be redesigned someday.

%    try 
        nohupfile = [SF_core_getopt('ffdatadir'),workdir,'nohup.out'];
%    catch
%        nohupfile = 'nohup.out';
%    end

%% LAUNCHING THE Time-stepping


SF_core_freefem(solver,'datadir',workdir,'wait',p.Results.wait,'arguments',ffargument,'meshfilename',meshfilename,'initfilename',initfilename,'nohupfile',nohupfile,'ncores',p.Results.ncores);


%% CHECK AND EXIT

folder = truedestination;
if ~p.Results.wait
    pause(2);
 %   if exist([folder,'TS.status'],'file')
 %       status = fileread([folder,'TS.status']);
 %       status = lower(status);
 %       if status(end)==char(10)&&length(status)>1
 %           status = status(1:end-1);
 %       end
 %       if strcmp(status,'running')
            SF_core_log('n',' Simulation running as a backgroud job');
            SF_core_log('n','');
            SF_core_log('n','    -> Use SF_TS_Check to check the status and the content ');
            SF_core_log('n','    -> You may use SF_TS_Stop("folder") to force the run to stop ');
            SF_core_log('n',['    -> Standart output of code is redirected to file ',nohupfile]);
  %      end
  %  else
  %      SF_core_log('w',' Could not detect if simulation is correctly running. Your solver should write "running" in a file "TS.status"');
  %  end
else
    SF_core_log('n',' Simulation correctly completed');
    SF_core_log('n','');
    SF_core_log('n',['    -> Use ts = SF_TS_Check(''',folder,''') to check the status and read the statistics files ']);
    
end

SF_core_log('d', '### END FUNCTION SF_TS_Launch');
pause(0.1);


end
