function sfstats = SF_Status(type,mode)
%>
%> This function allows to generate a useful summary of data present in the
%> working directories.
%> This can be useful to reconstruct structures from available data files,
%> for instance if you did a 'clear all' but data files are still present... 
%>
%> USAGE :
%> 1. SF_Status(DIRECTORY)
%>  -> check the content of folder ffdatadir/DIRECTORY
%> 
%> you can chose between the following directories :
%>      'MESHES'          (meshes available and corresponding baseflows)
%>      'BASEFLOWS'       (baseflows compatible with the current mesh)
%>      'MEANFLOWS'       (meanflows/HB flows compatible with the current mesh)
%>      'DNSFLOWS'        (dns snapshots compatible with the current mesh)
%>      'EIGENMODES'      (eigenmodes compatible with the current mesh)
%>      'MISC'            (miscleanous fields such as additions, masks, ...)
%>
%>  ( NB since version 3.5 (june 2020) the names of directories are not
%>    restricted any more to this list but can be chosen freely )
%>
%> 2. SF_Status()  [ or SF_Status('ALL') ]
%>  -> check all subfolders of ffdatadir
%>
%> 3. sfstats=SF_Status('ALL','quiet')
%>  (-> this last method is only for internal usage by SF_Load)
%>      sfstats has fields [LastMesh, LastAdaptedBaseFlow,LastComputedBaseFlow,LastComputedMeanFlow,LastDNS]
%>
%> NB this functions uses nestedSortStruct and SortStruct taken from
%> mathworks (to sort the files by dates)
%>

%% Options


if(nargin==0)
    type = 'all';
    mode = 'verbose';
end


if(nargin==1)
    mode = 'verbose';
end

if strcmpi(type,'quiet') 
    type = 'all'; % legacy fix
    mode = 'quiet';
end

if strcmp(mode,'verbose')
    isdisp=1; 
else
    isdisp=0;
end


if strcmpi(type,'cleanall')
  SF_core_arborescence('cleanall');
  return
end

if strcmpi(type,'clean')
  SF_core_arborescence('clean');
  return
end

ffdatadir = SF_core_getopt('ffdatadir');

sfstats = [];

mymydisp(isdisp,'################################################################################');
mymydisp(isdisp,'');
mymydisp(isdisp,['...  SUMMARY OF YOUR DATABASE FOLDER :    ', ffdatadir]);
mymydisp(isdisp,'');




%% checking problem type     
    
fileToRead2 = [SF_core_getopt('ffdatadir'), '/problemtype.ff2m'];
if(exist(fileToRead2,'file'))
    SF_core_log('d', ['FUNCTION  SF_Status.m : reading complementary file' fileToRead2]);
    m2 = SFcore_ImportData(fileToRead2);
  %  sfstats.problemtype = m2.problemtype;
else
     SF_core_log('d', ['FUNCTION  SFcore_ImportMesh.m : DO NOT FIND COMPLEMENTARY FILE ' fileToRead2]);
end

%% MESHES
if (strcmpi(type,'meshes') || strcmpi(type,'all') )
        thedir = dir([ffdatadir, 'MESHES/*.msh']); 
       % ii = 1;
       % for i = 1:length(thedir0)
       %   name = thedir0(i).name
       %   if ~(length(name)>7&&strcmp(name(end-6:end),'aux.msh')) 
       %     thedir(ii)=thedir0(i)
       %     ii=ii+1;
       %   end     
       % end
       % thedir
    if ~isempty(thedir)
        mymydisp(isdisp,'#################################################################################');
        mymydisp(isdisp,' ');
        mymydisp(isdisp,['.... CONTENT OF DIRECTORY ', ffdatadir, 'MESHES :']);
        mymydisp(isdisp,'     (list of meshes previously created/adapted ; couples of .msh/.ff2m files )');
        mymydisp(isdisp,' ');
        thestring='Index | Name              | generation mode | Date                 | Nv      ';
        metadata = SFcore_ImportData([SF_core_getopt('ffdatadir'), 'MESHES/',thedir(end).name],'metadataonly');
        if isfield(metadata,'INDEXING')
            indexnames = fieldnames(metadata.INDEXING);
            for ind = indexnames'
                thestring = [thestring ,' | ', SFpad(ind{1},10)];
            end
        else
            indexnames = [];
        end
        mymydisp(isdisp,thestring);
 %       thedir = nestedSortStruct(thedir, 'datenum');
        ii = 0;
        for i = 1:length(thedir)
          name = thedir(i).name;
          if ~(length(name)>7&&strcmp(name(end-6:end),'aux.msh')) 
            % warning : there may be some files with form ###_aux.msh which should not be counted
            ii = ii+1;
            date = thedir(i).date;
            metadata = SFcore_ImportData([SF_core_getopt('ffdatadir'), '/MESHES/',thedir(i).name],'metadataonly');
            if isfield(metadata,'generationmode')
                generationmode = metadata.generationmode;
            else
                generationmode = '(unknown)';
            end
            fid = fopen([ffdatadir, 'MESHES/', name], 'r');
            headerline = textscan(fid, '%f %f %f', 1, 'Delimiter', '\n');
            nv(ii) = headerline{1}; 
            fclose(fid);
            thestring = [num2str(ii), blanks(max(5-length(num2str(ii)),1)), ' | ', ...
                SFpad(name,16), ' | ', SFpad(generationmode,15), ' | ',...
                SFpad(date,20), ' | ',  SFpad(num2str(nv(ii)),8)];
             if isfield(metadata,'INDEXING')
                for ind = indexnames'
                    if isfield(metadata.INDEXING,ind{1})
                        value = metadata.INDEXING.(ind{1});
                        if(imag(value)==0)
                            thestring = [thestring ,' | ', SFpad(num2str(value),10)];
                        else
                            thestring = [thestring ,' | ', SFpad(num2str(value),16)];
                        end
                    else
                        thestring = [thestring ,' | ', SFpad('???',10)];
                    end
                end
             end
            mymydisp(isdisp,thestring);
            
            sfstats.MESHES(ii).MESHfilename = thedir(i).name;
            sfstats.MESHES(ii).date = date;
            sfstats.MESHES(ii).nv = nv(ii);
            
            % adding metadata
            if isfield(metadata,'INDEXING')    
                fff = fieldnames(metadata.INDEXING);
                for jj =  1:length(fff)
                    ff = fff{jj};
                    sfstats.MESHES(i).(ff) =metadata.INDEXING.(ff);
                end
            end

          end  
        end
        
%        sfstats.LastMesh = [ffdatadir, 'MESHES/',name];
    else
%        sfstats.LastMesh = [];
%        sfstats.MESHES = [];
        mymydisp(isdisp,'#################################################################################');
        mymydisp(isdisp,' ');
        mymydisp(isdisp,['.... NO MESH FOUND IN DIRECTORY ', ffdatadir, 'MESHES :']);
        mymydisp(isdisp,' ');
    end
    
if(strcmpi(type,'meshes')||strcmpi(type,'all'))
    [sfstats,flag] = SF_core_Status(sfstats,'MESHES',isdisp); 
 
        mymydisp(isdisp,' ');
%        mymydisp(isdisp,' REMINDER : PROCEDURE TO LOAD A PREVIOUSLY COMPUTED MESH')
%        mymydisp(isdisp,' simply type the following command  (where index is the number of the desired mesh or keyword ''last'')');
%        mymydisp(isdisp,' ');
%        mymydisp(isdisp,'    mesh = SF_Load(''MESH'',index)');
%        mymydisp(isdisp,' ');
        if (flag==0)
        mymydisp(isdisp,' SIMILARLY : TO LOAD THE FIRST BF ASSOCIATED TO A MESH (not recommended)')
        mymydisp(isdisp,'    bf = SF_Load(''MESH+BF'',index)');
        mymydisp(isdisp,' ');
        end
        
end 
        mymydisp(isdisp,'#################################################################################');
       % mymydisp(isdisp,' ');
%    end  
 if  (flag==1&&strcmp(mode,'verbose'))
      SF_core_log('nnn','WARNING : number of Meshes and Baseflows in directory MESHES differ !');
end
end



%% BASEFLOWS
if(strcmpi(type,'baseflows')||strcmpi(type,'all'))
    sfstats = SF_core_Status(sfstats,'BASEFLOWS',isdisp);
end

%% Checking directory EIGENMODES
if(strcmpi(type,'eigenmodes')||strcmpi(type,'all'))
    sfstats = SF_core_Status(sfstats,'EIGENMODES',isdisp);
end

%% checking statistics file

if exist([ffdatadir 'STATS/StabStats.txt'],'file') && strcmpi(type,'all')
  Stabstats = SFcore_ImportData([ffdatadir 'STATS/StabStats.txt']);
  if ~isempty(Stabstats)
    neig = length(Stabstats.lambda);
    mymydisp(isdisp,' ');
    mymydisp(isdisp,[' You have previously computed ',num2str(neig), ' eigenvalues in this session'] );
    mymydisp(isdisp,' The full list will be available as field  ''EIGENVALUES'' of this function''s result');
    mymydisp(isdisp,' ');
    Stabstats = rmfield(Stabstats,{'filename','DataDescription','datatype','datastoragemode','datadescriptors'});
    sfstats.EIGENVALUES = Stabstats;
  else 
%    sfstats.EIGENVALUES = [];
    mymydisp(isdisp,'Nothing found in file STATS/StabStats.stat'); 
  end
else  
%  sfstats.EIGENVALUES = [];
  SF_core_log('nnn','Not found any file STATS/StabStats.stat'); 
end


%% checking THRESHOLD statistics file

if exist([ffdatadir 'STATS/StatThreshold.txt'],'file') && strcmpi(type,'all')
  Stabstats = SFcore_ImportData([ffdatadir 'STATS/StatThreshold.txt']);
  if ~isempty(Stabstats)
    neig = length(Stabstats.lambda);
    mymydisp(isdisp,' ');
    mymydisp(isdisp,[' In these computations you have identified ',num2str(neig), ' neutral ceigenvalues'] );
    mymydisp(isdisp,' The full list will be available as field  ''THRESHOLD'' of this function''s result');
    mymydisp(isdisp,' ');
    Stabstats = rmfield(Stabstats,{'filename','DataDescription','datatype','datastoragemode','datadescriptors'});
    sfstats.THRESHOLDS = Stabstats;
  else 
%    sfstats.THRESHOLDS = [];
    mymydisp(isdisp,'Nothing found in file STATS/StatThreshold.txt'); 
  end
else  
%  sfstats.THRESHOLDS = [];
  SF_core_log('nnn','Not found any file STATS/StatThreshold.txt'); 
end


%% DNSFLOWS (OLD METHOD)
if(strcmpi(type,'dnsflows'))% || strcmpi(type,'all'))
    sfstats = SF_core_Status(sfstats,'DNSFIELDS',isdisp);
end


if exist([ffdatadir 'STATS/dns_Stats.txt'],'file') && strcmpi(type,'all')
  DNSstats = SFcore_ImportData([ffdatadir 'STATS/dns_Stats.txt']);
  if isfield(DNSstats,'t')
    neig = length(DNSstats.t);
    mymydisp(isdisp,' ');
    mymydisp(isdisp,' Detected a DNS statistics file STATS/dns_Stats.txt (NB THIS IS OBSOLETE METHOD FOR DNS ! PLEASE UPDATE TO NEW METHOD');
    mymydisp(isdisp,[' You have previously computed ',num2str(neig), ' time steps of DNS'] );
    mymydisp(isdisp,' The full list will be available as field  ''DNSSTATS'' of this function''s result');
    mymydisp(isdisp,' ');
    Stabstats = rmfield(DNSstats,{'filename','DataDescription','datatype','datastoragemode','datadescriptors'});
    sfstats.DNSSTATS = DNSstats;
  else 
%    sfstats.DNSSTATS = [];
    mymydisp(isdisp,'Nothing found in file STATS/dns_Stats.txt'); 
  end
else  
%  sfstats.DNSSTATS = [];
  SF_core_log('nnn','Not found any file STATS/dns_Stats.txt'); 
end




%% DNSSTATS (only check size)
%if(strcmpi(type,'misc') || strcmpi(type,'all'))
%    sfstats = SF_core_Status(sfstats,'DNSSTATS',isdisp);
%end

%% NEW METHOD TO SCAN ALL OTHER DIRECTORIES

list_reserved_dirs = {'MESHES','BASEFLOWS','EIGENMODES','DNSFLOWS','STATS','.','..'};
dd = dir(SF_core_getopt('ffdatadir'));
for j = 1:length(dd)

    if(strcmpi(type,dd(j).name)||strcmpi(type,'all'))&&dd(j).isdir&&~any(strcmp(dd(j).name,list_reserved_dirs))
        sfstats = SF_core_Status(sfstats,dd(j).name,isdisp);
    end
end

%% NEW METHOD FOR TIME-STEPPING SIMULATION (REPLACING 'DNS')

if (strcmpi(type,'timestepping')||strcmpi(type,'all'))
  if isdisp==0
    sfts = SF_TS_Check('quiet');
  else 
    sfts = SF_TS_Check;
  end

  if ~isempty(sfts)
   sfstats.TimeStepping = sfts;
  end

mymydisp(isdisp,'#################################################################################');
 
end





%% legacy       
  %if ~isfield(sfstats,'MESHES')||isempty(sfstats.MESHES)
  %  sfstats.status = 'new';
  %else
  %  sfstats.status = 'existent';
  %end

  
  
%% end of function

end 



%%
function mymydisp(isdisp,string)
if(isdisp)
    disp(string);
end
end

%function Nfiles = countfiles(directory,suffix)
%  thedir = dir([directory,'/*',suffix]);
%  Nfiles = length(thedir)
%  if strcmp(suffix,'.msh')
%    thedir = dir([directory,'/*_aux.msh']);
%    Nfilesaux = length(thedir)
%    Nfiles = Nfiles-Nfilesaux;
%  end
%end

% function Snew = arrayofstructs2strucofarrays(S)
% try 
%  SF_core_log('d','converting array of structs to struct of arrays...');  
%  thefields = fieldnames(S(1));
%     for j=1:length(thefields)
%         tt = [];
%         for i=1:length(S)
%             if isnumeric(S(i).(thefields{j}))
%                 tt(i) = S(i).(thefields{j});
%             end
%             if ischar(S(i).(thefields{j})) 
%                 tt{i} = S(i).(thefields{j});
%             end
%         end
%         Snew.(thefields{j}) = tt;
%     end
%     S = Snew;
% catch
%     SF_core_log('w', 'error in arrayofstructs2strucofarrays : returning initial object');
%     Snew = S;
% end
% end

    
    