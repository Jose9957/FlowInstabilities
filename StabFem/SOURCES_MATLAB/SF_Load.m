function flow = SF_Load(mode,index,index2)
%>
%> function SF_Load
%> 
%> This function is used to load previously computed meshes/baseflows ;
%> useful when restarting from previously computed data
%>
%> USAGE : 
%>
%>   (RECOMMENDED MODES)
%>
%>    Field = SF_Load('THEDIRECTORY',i)
%>    where 'THEDIRECTORY Is a valid folder in the database (subfolder of ffdatadir)
%>           i is the index or keyword 'last'
%>
%>   (LEGACY MODES)
%>
%>   1/ bf = SF_Load('mesh+bf',i)
%>      -> load mesh/baseflow number i found in the MESHES/ subfolder
%>
%>   2/ bf = SF_Load('bf',i)
%>      -> load baseflow number i found in the BASEFLOW/ subfolder
%>
%>   3/ bf = SF_Load('EIGENMODE',i)
%>      -> load eigenmode number i found in the EIGENMODES/ subfolder
%>
%>   3b/ bf = SF_Load('EIGENMODE',filename)
%>      -> load eigenmode found in the EIGENMODES/ subfolder matching filename
%>
%>
%> (next options are obsolete/not validated ?)
%>
%>   3/ mesh = SF_Load('lastmesh')
%>       -> load mesh only
%> 
%>   4/ bf = SF_Load('lastadaptedbaseflow')
%>    
%>   5/ bf = SF_Load('lastbaseflow')
%>
%>   6/ mf = SF_Load('lastmeanflow') ( NOT YET VALIDATED !)
%>
%>   7/ dnsflow = SF_Load('lastDNS')
%>
%> This program belongs to the StabFem project, freely distributed under GNU licence.
%> copyright D. Fabre, 31 march 2019
%
% WARNING : for directory MESHES we have an array of structs while for othe
% cases we have struct of arrays !
%
% 
% NB THIS FUNCTION IS VERY MESSY BUT FUNCTIONAL... 
% to be rewritten or better translated in python ! 
%

if nargin==2
  index2 = 0;
end

SF_core_log('dd','Entering SF_Load')


if ~strcmp(mode,'TimeStepping')

if exist([SF_core_getopt('ffdatadir'),'/',mode],'dir')
    sfstats = SF_Status(mode,'QUIET'); %% should be avoided here. and use index
elseif exist(mode,'dir')
    mode = mode(length(SF_core_getopt('ffdatadir'))+1:end);
    sfstats = SF_Status(mode,'QUIET');
else
    sfstats = SF_Status('ALL','QUIET');
    SF_core_log('w','Obsolete usage of SF_Load : must specify a folder')
end
 
if (nargin==1) 
    index = 'last';
end

else
    sfstats = 'TimeStats'; % required only because the programing is very bad....
end

if strcmpi(mode,'meshes')
    SF_core_log('l','Reading from directory "MESHES" : are you sure of what your are doing ???');
    SF_core_log('l',' Recommended usage   a/  "SF_Load(''MESH'',n)" to load mesh number n');
    SF_core_log('l','                     b/  "SF_Load(''MESH+BF'',n)" to load baseflow associated to mesh number n (lecacy mode)');
end


if (~isempty(sfstats))%&&~isempty(sfstats.MESHES))
    switch lower(mode)
    
     case({'meshes','mesh'})
        if ~isempty(sfstats.MESHES)
            if (nargin>1)&&ischar(index)&&strcmp(index,'last')
                index = length(sfstats.MESHES);
            elseif (nargin>1)&&isnumeric(index)&&(index<=0)
                index = length(sfstats.MESHES)+index;
            end
            SF_core_log('nnn',['Loading mesh only ; number ',num2str(index)]);
            flow = SFcore_ImportMesh(['MESHES/',sfstats.MESHES(index).MESHfilename]);
        end 
    case({'mesh+bf','bf+mesh'})
        if ~isempty(sfstats.MESHES)
            if (nargin>1)&&ischar(index)&&strcmp(index,'last')
                index = length(sfstats.MESHES);
             elseif (nargin>1)&&isnumeric(index)&&(index<=0)
                index = length(sfstats.MESHES)+index;    
            end
            SF_core_log('n',['Loading mesh + associated baseflow number ',num2str(index)]);
            SF_core_log('e','This method is not operational any more ');
%            ffmesh = SFcore_ImportMesh(['MESHES/',sfstats.MESHES(index).MESHfilename]);
%            ffmesh = setsym(ffmesh);
%            flzzzZZow   = SFcore_ImportData(ffmesh,[sfstats.MESHES(index).filename]); 
            if isfield(sfstats.MESHES(index),'filename')
                flow   = SFcore_ImportData(sfstats.MESHES(index).filename);
                if (isfield(flow,'iter')&&flow.iter==-1)
                    SF_core_log('w','bf.iter = -1 ! It seems the base flow you imported diverged !')
                elseif (isfield(flow,'iter')&&flow.iter==0)
                    SF_core_log('w','bf.iter = 0 ! It seems your baseflow was projected on a new mesh but not recomputed !')
                    SF_core_log('w','              It is advised that you run SF_BaseFlow again ')
                    SF_core_log('w','              The program will try this without guarranty of success')
                    flow = SF_BaseFlow(flow);
                end
            else
               flow = [];
               SF_core_log('w','Requested mesh not found');
            end
        else
            flow = [];
            SF_core_log('e','Requested mesh not found');
        end
    
    case({'bf','baseflow','baseflows'})
        if isfield(sfstats,'BASEFLOWS')&&~isempty(sfstats.BASEFLOWS)
            if ischar(index) && strcmp(index,'last')
              index = length(sfstats.BASEFLOWS);
            elseif (nargin>1)&&isnumeric(index)&&(index<=0)
                index = length(sfstats.BASEFLOWS)+index;   
            end
            if index<=0
              index = length(sfstats.BASEFLOWS)+index;
            end
            SF_core_log('n',['Loading baseflow number ',num2str(index)]);
            flow   = SFcore_ImportData(sfstats.BASEFLOWS(index).filename); 
        else
            flow = [];
            SF_core_log('w','Requested base flow not found');
        end
        
        
    case ('timestepping')
%    try
      folder = ['TimeStepping/RUN',sprintf( '%06d', index ),'/']; 
      if ischar(index2)&& strcmp(index2,'last')
          index2 = 0;
      end
       if index2<=0
              A = dir([SF_core_getopt('ffdatadir'),folder,'Snapshot_*.txt']);
              file = [folder,A(end+index2).name];
              SF_core_log('n',[' Loading Snaphot # (last - ',num2str(-index2),') from run #',num2str(index)]);  
       else
            SF_core_log('n',[' Loading Snaphot #',num2str(index2),' from run #',num2str(index)]);  
            file = [folder,'Snapshot_',sprintf( '%08d', index2 ),'.txt'];
       end
      
      flow = SFcore_ImportData(file);
%    catch
%      SF_core_log('e', 'Loading Snapshot failed')
%    end
      
        
        case({'dns','dnsfield','dnsfields'})
            SF_core_log('w',' SF_Load with dns may not be operational anymore');
        if ~isempty(sfstats.DNSFIELDS)
            if ischar(index) && strcmp(index,'last')
              index = length(sfstats.DNSFIELDS);
            elseif (nargin>1)&&isnumeric(index)&&(index<=0)
                index = length(sfstats.DNSFIELDS)+index;   
            end
            SF_core_log('n',['Loading dns snapshot number ',num2str(index)] );
            flow   = SFcore_ImportData(sfstats.DNSFIELDS(index).filename);
        else
            flow = [];
            SF_core_log('e','Requested base flow not found');
        end    
        
    case({'eigenmode','eigenmodes'})
        if ~isempty(sfstats)%.MESHES)
            if ischar(index) && strcmp(index,'last')
              index = length(sfstats.EIGENMODES);
            elseif (nargin>1)&&isnumeric(index)&&(index<=0)
                index = length(sfstats.EIGENMODES)+index;   
            end
            if ~ischar(index) 
               filename = sfstats.EIGENMODES(index).filename;
            else
                [~,f,d] = fileparts(index); 
                filename = [f,d]; % must work as well if there is a path
            end
            SF_core_log('n',['Loading EIGENMODE number ',num2str(index) ]); 
            flow   = SFcore_ImportData(filename); 
            if isfield(flow,'baseflowfilename')
                bf = SFcore_ImportData(flow.baseflowfilename,'metadataonly');
                flow.BFINDEXING = bf.INDEXING;
            end
%            if isfield(flow,'meshfilename')
%                mesh = SFcore_ImportMesh(flow.meshfilename,'metadataonly');
%                flow.MESHINDEXING =mesh.INDEXING;
%            end
            
        else
            flow = [];
            SF_core_log('e','Requested eigenmode not found');
        end
       
    case('meshonly') % obsolete
        if (nargin>1)&&ischar(index)&&strcmp(index,'last')
          index = length(sfstats.MESHES);
        elseif (nargin>1)&&isnumeric(index)&&(index<=0)
                index = length(sfstats.MESHES)+index;   
        end
        SF_core_log('n',['Loading mesh number ',num2str(index)]);
        flow   = SFcore_ImportMesh(['MESHES/',sfstats.MESHES(index).MESHfilename]);     
    
    % next modes are not to be used any more
    case('lastmesh')
        if ~isempty(sfstats.MESHES)
            ffmesh = SFcore_ImportMesh(['MESHES/',sfstats.MESHES(end).MESHfilename]);
            ffmesh = setsym(ffmesh);
            flow = ffmesh;
            SF_core_log('n',['Loading last adapted mesh : ' sfstats.MESHES(end).MESHfilename]);
        else
            flow = [];
            SF_core_log('n','Last mesh not found');
        end
            
    case({'lastadaptedbaseflow','lastadapted'})
        if ~isempty(sfstats.MESHES)
            SF_core_log('w','Loading last adapted mesh + associated baseflow ');
            SF_core_log('e','Not recommended any more to do this !!');
           % ffmesh = SFcore_ImportMesh(['MESHES/',sfstats.MESHES(end).MESHfilename]);
           % ffmesh = setsym(ffmesh);
           % flow = SFcore_ImportData(ffmesh,sfstats.MESHES(end).filename);
            flow = SFcore_ImportData(sfstats.MESHES(end).filename);
            SF_core_log('n','Loading last adapted bf+mesh : ')
            SF_core_log('n',['    -> Mesh      : ', sfstats.MESHES(end).MESHfilename]);  
            SF_core_log('n',['    -> Base FLow : ', sfstats.MESHES(end).filename]);  
        else
            flow = [];
            SF_core_log('n','Last mesh not found');
        end
        
    case({'lastbaseflow','lastcomputed'})
        if ~isempty(sfstats.BASEFLOWS)
%            ffmesh = SFcore_ImportMesh(['MESHES/',sfstats.LastMesh]);
%            ffmesh = setsym(ffmesh);
            flow = SFcore_ImportData(sfstats.BASEFLOWS(end).filename);
            SF_core_log('n',['Importing last base flow :' sfstats.BASEFLOWS(end).filename]);
        else
            flow = [];
            SF_core_log('n','Last base flow not found');
        end
        
    case('lastmeanflow')% not validated
       % ffmesh = SFcore_ImportMesh(sfstats.LastMesh);
       % ffmesh = setsym(ffmesh);
        flow = SFcore_ImportData(sfstats.LastComputedMeanFlow);
    case('lastdns') % not validated
       % ffmesh = SFcore_ImportMesh(sfstats.LastMesh);
       % ffmesh = setsym(ffmesh);
        flow = SFcore_ImportData(sfstats.LastDNS);
    
    otherwise
        %% GENERIC CASE (to be generalized)
       if exist([SF_core_getopt('ffdatadir'),'/',mode],'dir')
            if ischar(index) && strcmp(index,'last')
              index = length(sfstats.(mode));
            elseif (nargin>1)&&isnumeric(index)&&(index<=0)
                index = length(sfstats.(mode))+index;   
            end
            SF_core_log('n',['Loading field number ',num2str(index), ' from folder ',mode]);
            if (index<=length(sfstats.(mode)))
                flow   = SFcore_ImportData(sfstats.(mode)(index).filename); 
            else
                flow = [];
                SF_core_log('w','Requested dataset not found in the specified folder' );
            end
        else
            flow = [];
            SF_core_log('w',['Requested dataset not found: inexistent or empty folder ',mode] );
        end  
            
    end
    

    
    
else
    flow = [];
end

end
  
function ffmesh = setsym(ffmesh)
       %sets keyword 'symmetry'       
        if (ismember(6,ffmesh.labels)&&abs(min(ffmesh.points(2,:)))<1e-10)
            sym = 1;
            SF_core_log('nn','IN SF_Load : assuming symmetry = 1 (''S'') ');
        else
            sym = 0;
            SF_core_log('nn','IN SF_Load : assuming symmetry = 0 (''N'') ');
        end
        ffmesh.symmetry=sym; 
end
