function [DNSstats,DNSfields] = SF_DNS(varargin)
%>
%> This is part of StabFem Project, D. Fabre, July 2017 -- present
%> Matlab driver for DNS
%>
%> USAGE :
%>    [DNSstats,DNSfields] = SF_DNS(DNS_Start,'Re',Re,'dt',dt,'itmax',itmax,[...])
%>    
%>  INPUT PARAMETERS : 
%>      DNS_Start is either a baseflow/meanflow or a previous DNS result
%>      (if an array of fields is probided, the last instant will be taken)
%>
%> OPTIONAL PARAMETERS :
%>
%> RESULTS :
%>    DNSstats : arrays containing time statistics 
%>               (history of lift,drag, or other customisable statistics)
%>
%>    DnsFields : array(N) of fields produced each iout time steps
%>
%> Notes : 
%>  1/ if the first argument is an array of snapshots, the result
%> 'DNSfields' will be an array with the new results appended at the end of
%>  the previous ones.
%>  2/ if using 'PreviousStats',true the result DNSstats will append the
%>   new statistics to all previously performed calculations. 
%>

SF_core_log('w', 'Driver SF_DNS is obsolete ! Please use now SF_TS_Launch / SF_TS_Check (see manual)');
SF_core_log('l', 'Driver SF_DNS is obsolete ! Please use now SF_TS_Launch / SF_TS_Check (see manual)') 
 

ffdatadir = SF_core_getopt('ffdatadir');

SF_core_arborescence('cleantmpfiles'); 

startfield = varargin{1}(end);
ffmesh = startfield.mesh;
vararginopt = {varargin{2:end}};

p = inputParser;
addParameter(p, 'Re', 100);
addParameter(p, 'Ma', 0.2);
addParameter(p, 'Omegax', 0.0);
addParameter(p, 'rep',0);
addParameter(p, 'itmax', 0); % max step number
addParameter(p, 'Nit',1000 ); %  number of step
% NB you should provide either itmax or Nit but not both !
addParameter(p, 'dt', 5e-3);
addParameter(p, 'iout', 10);
addParameter(p, 'istat', 1);
addParameter(p, 'mode', 'init');
addParameter(p, 'Mach', 0.05);
addParameter(p, 'Vcav', 1);
addParameter(p, 'Vin', 1);
%addParameter(p, 'startmode',[]);
%addParameter(p, 'amplitudemode',1e-3,@isnum);
addParameter(p, 'dir',[ffdatadir 'DNSFIELDS'])  ;
addParameter(p,'PreviousStats',false); % -> if true statistics will cover full DNS not only last run
addParameter(p,'solver','');
parse(p, vararginopt{:});

% positioning mesh file
SFcore_MoveDataFiles(startfield.mesh.filename,'mesh.msh','cp');

% positioning initial condition file
switch lower(startfield.datatype)
    case {'baseflow','meanflow','addition'} 
        rep = 0;
        if strcmpi(p.Results.mode,'init')
            myrm([ffdatadir,'dns_Stats.ff2m']);
        end
        SF_core_log('n', ['FUNCTION SF_DNS : starting from BF / MF (reset it = 0)']);
            %mycp(startfield.filename, [ffdatadir, 'dnsfield_start.txt']);
            SFcore_MoveDataFiles(startfield.filename,'dnsfield_start.txt','cp');
             
    case 'dnsfield'
        rep = startfield.it;
       SF_core_log('n', ['FUNCTION SF_DNS : starting from previous DNS result with it = ', num2str(rep)]);
        SFcore_MoveDataFiles(startfield.filename,['dnsfield_',num2str(rep),'.txt'],'cp');
end

if ~(exist([ffdatadir 'DNSFIELDS'],'dir'))
    mymake([ffdatadir 'DNSFIELDS']);
end

    
if(p.Results.itmax==0)  
    itmax = rep+p.Results.Nit;
else
    itmax = p.Results.itmax;
end


SF_core_log('n', ['         Time-stepping up to it = ',num2str(itmax) ' ( number of steps = ' num2str(itmax-rep) ' ) ']);
iout = p.Results.iout;

 itout = [ceil(rep/iout)*iout:iout:floor((itmax-1)/iout)*iout, itmax];
 % this is the expected set of files to import 
 % TODO : automatic importation of all present files instead of making expectations 
 
%% launch ff++ code

switch (lower(startfield.mesh.problemtype))

    case('unspecified')
        if ~isempty(p.Results.solver)
            FFsolver = p.Results.solver;
        else
            SF_core_log('e','You must specity a solver !');
        end
        optionstring = [' ', num2str(p.Results.Re), ' ', num2str(rep), ' ',num2str(itmax), ' ',num2str(p.Results.dt), ' ',num2str(p.Results.iout), ' ', num2str(p.Results.istat), ' ', num2str(p.Results.Omegax)];
        SF_core_log('l','Interface to time-stepper not yet generic; to be improved using getARGV');
    
    case('2d')
        FFsolver = 'TimeStepper_2D.edp'; % default
        optionstring = [' ', num2str(p.Results.Re), ' ', num2str(rep), ' ',num2str(itmax), ' ',num2str(p.Results.dt), ' ',num2str(p.Results.iout), ' ', num2str(p.Results.istat), ' ', num2str(p.Results.Omegax)];
    
    case('axixracomp')
        FFsolver = 'TimeStepper_Axi_AComp_Pert.edp'; % axisymmetric augmented compressibility
        optionstring = [' ', num2str(p.Results.Re), ' ', num2str(rep),...
                        ' ',num2str(itmax), ' ',num2str(p.Results.dt),...
                        ' ',num2str(p.Results.iout), ' ',...
                        num2str(p.Results.istat), ' ',...
                        num2str(p.Results.Mach), ' ',...
                        num2str(p.Results.Vcav), ' ',...
                        num2str(p.Results.Vin)];

  % case("your case...")
        % add your case here !
        
    otherwise
        error(['Error in SF_HB2 : your case ', startfield.mesh.problemtype 'is not yet implemented....'])
        
    end

    if ~isempty(p.Results.solver)
        FFsolver = p.Results.solver;
        SF_core_log('n','SF_DNS : Using alternative solver ');
    end
%    command = ['echo ', optionstring, ' | ', ff, ' ',ffdir,FFsolver];

if(~strcmp(p.Results.mode,'postprocessonly')) % OBSOLETE
    SF_core_log('N','Launching DNS...');
    SF_core_freefem(FFsolver,'parameters',optionstring);
else
    SF_core_log('N','Importation of a previous dataset from DNS...');
end


%%% First import "statistics" file
  

    filenameFULL = SFcore_MoveDataFiles('dns_Stats.ff2m','STATS/dns_Stats.ff2m','app'); %'app' refers to the .txt file
    DNSstatsFULL = SFcore_ImportData(filenameFULL);
    filenameRUN = SFcore_MoveDataFiles('dns_Stats.ff2m','STATS','mv');
    DNSstatsRUN = SFcore_ImportData(filenameRUN);
    if p.Results.PreviousStats
        DNSstats = DNSstatsFULL; 
    else
        DNSstats = DNSstatsRUN; 
    end
    
    DNSFiles = dir([SF_core_getopt('ffdatadir'),'dnsfield_*.txt']);
 
    for i = 1:length(DNSFiles)
        if strcmp(DNSFiles(i).name,'dnsfield_start.txt') 
            continue
        end
 
     SFcore_AddMESHFilenameToFF2M(DNSFiles(i).name,ffmesh.filename);   
     dnsfilename = SFcore_MoveDataFiles(DNSFiles(i).name,'DNSFIELDS','mv');

           if (exist(dnsfilename,'file'))
               DNSfields(i) = SFcore_ImportData(dnsfilename);
           else
             SF_core_log('w','WARNING : DNS HAS DIVERGED ')
             break
           end
    end

    if length(varargin{1})>1
        
        SF_core_log('n','Gluing DNSfields with previous snapshots')
        DNSfields = [varargin{1} DNSfields];        
    end
    
    % eventually clean working directory from temporary files

    SF_core_log('d', '### END FUNCTION SF_DNS');
end
