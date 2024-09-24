function [DNSstats,DNSfields]  = SF_TS_Check(varargin)
%
% FUNCTION SF_TS_Check
%
% This function is used to check the results of Time-Stepping simulations contained in your database folder.
%
% USAGE :
% 1/  sft = SF_TS_Check(run)
%        To check the content of a folder corresponding to a given run.
%          (argument "run" is either the path name, e.g. "./WORK/TimeStepping/RUN00001" or the index of the run, e.g. 1).
%        The return object is a structure containing the time-statistics from the .txt/.ff2m files found in the folder.
%
% 2/  [sft,Snap] = SF_TS_Check(run)
%        To check the content of the folder and read the whole series of snapshots.
%        The second return object is an array of structures corresponding to all snapshots.
%
% 3/  sft = SF_TS_Check
%         To check the content of all runs stored in your current database.
%         The return objet is an array of structures.
%
% 4/  sft = SF_TS_Check('quiet')
%         Same as usage 3  but nothing is displayed on screen
%
% History : created june 2021 by DF to replace old method using SF_DNS.
%
% This file belongs to the StabFem project freely disctributed under gnu licence.

isdisp = 1;

if (nargin==0)&&(strcmp(SF_core_getopt('ffdatadir'),'./')||isempty(SF_core_getopt('ffdatadir')))
    [DNSstats,DNSfields]  = SF_TS_Check(0);
    return
end

if (nargin==0||strcmpi(varargin{1},'all')||strcmpi(varargin{1},'running')||strcmpi(varargin{1},'finished')||strcmpi(varargin{1},'quiet')||strcmpi(varargin{1},'short'))
    %% Full summary
    if nargin>=1&&strcmpi(varargin{1},'quiet')
        isdisp = 0;
    elseif nargin>=1&&strcmpi(varargin{1},'short')  
        isdisp = 2;
    else
        isdisp = 1;
    end
    DNSFiles = dir([SF_core_getopt('ffdatadir'),'TimeStepping']);
    DNSfields=[];
    if length(DNSFiles)>2
        mymydisp(isdisp,'#################################################################################');
        mymydisp(isdisp,'');
        mymydisp(isdisp,['.... Checking for simulation results in folder ', SF_core_getopt('ffdatadir'), 'TimeStepping']);
        mymydisp(isdisp,'');
        i0 = 1;
        for i = 1:length(DNSFiles)
            if contains(DNSFiles(i).name,'RUN')
                stru = SF_TS_Check([SF_core_getopt('ffdatadir'),'TimeStepping/',DNSFiles(i).name],isdisp);
                if ~isempty(stru)
                    try
                        DNSstats(i0) = stru;
                    catch
                        SF_core_log('w',' Metadata and/or time series incorreclty detected in this folder');
                    end
                end
                i0=i0+1;
            end
        end
    else
        DNSstats = [];
    end
    
elseif nargin>=1
    %% Summary of a single directory
    if nargin>=2
        isdisp=varargin{2};
    else
        isdisp=1;
    end
    folder = varargin{1};
    if isnumeric(folder)&&folder>0
        folder = [SF_core_getopt('ffdatadir'),'TimeStepping/RUN',sprintf('%06d',folder),'/'];
    elseif isnumeric(folder)&&folder==0
        folder = './';
    end
    SF_core_log('d',['checking Time-Stepping results in folder ',folder, '.....']);
    
    %    try
    %% Check only one folder
    if ~strcmp(folder(end),'/')
        folder = [folder, '/'];
    end
    
    mymydisp(isdisp,'#################################################################################');
    mymydisp(isdisp,'')
    mymydisp(isdisp,['.... CONTENT OF  ', folder, ' : ']);
  
  %% detect status according to files TS.status and/or EarlyDNSend.txt and/or hohup.out  
  try
    if exist([folder,'TS.status'],'file')
        SF_core_syscommand('cp',[folder,'TS.status'],[folder,'TS.status2']);
        status = fileread([folder,'TS.status2']);
        status = lower(status);
        if status(end)==char(10)&&length(status)>1
            status = status(1:end-1); %NB use fscanf instead should be better
        end
    elseif exist([folder,'EarlyDNSend.txt'],'file')
        statusnum = fileread([folder,'TS.status']);
        if statusnum==0
            status = 'running';
        elseif statusnum==1
            status = 'stopped';
        else
            status = 'unknown';
        end
    else 
        SF_core_log('nnn',' No file TS.status (or EarlyDNSend.txt) was found. It is highly advised to create one. see stabfem documentation.');
        status = 'unknown';
    end
    if (strcmpi(status,'running')||strcmpi(status,'unknown'))
      A= dir([folder,'nohup.out']);
      if ~isempty(A)
        if( (datenum(now)-A.datenum)*60*24 > 10) % this file was not touched in the past 10 minutes
            status = 'aborted';
        end
      end
    end
  catch
    status = 'unknown';
  end
        switch status
            case 'completed'
                statuslog = ' Simulation completed';
            case 'running'
                statuslog = ' Simulation still running';
            case {'stopped','s'}
                statuslog = ' Simulation stopped by SF_TS_Stop (or EarlyEnding signal)';
            case 'diverged'
                statuslog = ' Simulation diverged';
            case 'aborted'
                statuslog = ' Simulation aborted';
            case 'unknown'
                statuslog = ' Simulation status could not be determined';
            otherwise
                SF_core_log('w',[' Status incorrectly detected ; file TS.status is  ',status]);
                statuslog = '';
        end
        
   mymydisp(isdisp,statuslog);
   if (isdisp==2)
       isdisp = 0;
   end
    
    %% displaying details on simulation from file Simulation.log created at launching
    try
        if (isdisp)
            type([folder,'/Simulation.log']);
        end
    catch
        SF_core_log('w','No file Simulation.log');
    end
    %% Importing TimeStats
    if exist([folder,'TimeStats.txt'],'file')
        DNSstats = SFcore_ImportData([folder,'TimeStats.ff2m']);
        if isfield(DNSstats,'iter')
            iter0 = DNSstats.iter(1);
            
            
            mymydisp(isdisp,[' -> Found time series spaning from iter = ',num2str(DNSstats.iter(1)) ' to ' ,num2str(DNSstats.iter(end)),...
                ' ; time = ',num2str(DNSstats.t(1)), ' to ',num2str(DNSstats.t(end))  ]);
        else
            iter0 = 0;
            DNSstats.iter = 0;
        end
        
        DNSFiles = dir([folder,'Snapshot_*.txt']);
    else
        disp('no time series found !')
        SF_core_log('w','No time series found here !');
        DNSstats = [];
        DNSfields = [];
        return;
    end
    
    DNSstats.status = status;
    %% Importing snapshots if required
    if (nargout==2)
        
        if length(DNSFiles)>0
            mymydisp(isdisp,[' -> Found ', num2str(length(DNSFiles)), ' Snapshots in this folder. Importing them....']);
            
            % addind meshfilename if not already available
            if exist([folder,'.meshfilename'],'file')
                SF_core_log('d',' Appending meshfilename to .ff2m files')
                fid = fopen([folder,'.meshfilename'],'r');
                meshfilename = fscanf(fid,'%s');
                fclose(fid);
                for i = 1:length(DNSFiles)
                    SFcore_AddMESHFilenameToFF2M([folder,DNSFiles(i).name],meshfilename);
                end
                SF_core_syscommand('rm',[folder,'.meshfilename']);
            end
            
            % importing
            for i = 1:length(DNSFiles)
                Snap(i) = SFcore_ImportData([folder,DNSFiles(i).name],'metadataonly');
            end
            DNSfields = Snap;
            
        else
            SF_core_log('w','No snapshots found here !')
            DNSfields = [];
        end
    else
        %% if not required
        mymydisp(isdisp,[' -> Found ', num2str(length(DNSFiles)), ' Snapshots in this folder.']);
        SF_core_TS_Status([],folder,isdisp);
    end
    
    % eventually clean working directory from temporary files
    
    %    catch
    %        SF_core_log('w','Error in checking thois folder')
    %    end
    
    if isfield(DNSstats,'mesh')
        DNSstats = rmfield(DNSstats,'mesh');
        SF_core_log('l',' There was a "mesh" field ; removing');
    end
    
mymydisp(isdisp,statuslog);    
mymydisp(isdisp,' ');
end

mymydisp(isdisp,' ');
SF_core_log('d', '### END FUNCTION SF_TS_Check');


end

function mymydisp(isdisp,string)
if(isdisp)
    disp(string);
end
end
