
function [sfstats,flag] = SF_core_Status(sfstats,folder,isdisp)
  %% Function SF_core_Status
  ffdatadir = SF_core_getopt('ffdatadir');
  
  if contains(folder,ffdatadir)
    folder = folder(length(ffdatadir)+1:end);
  elseif length(ffdatadir)>2&&contains(folder,ffdatadir(3:end))
    folder = folder(length(ffdatadir)+1:end);
  end

    flag=1;
     thedir = dir([SF_core_getopt('ffdatadir'), folder,'/Snap*.txt']);    
     if ~isempty(thedir)
        mymydisp(isdisp,'#################################################################################');
        mymydisp(isdisp,' ');
        if ~strcmp(folder,'MESHES')
          mymydisp(isdisp,['.... SNAPSHOTS FOUND IN DIRECTORY ', SF_core_getopt('ffdatadir'), folder]);
          mymydisp(isdisp,'     (couples of .txt/.ff2m files )');
          if strcmpi(folder,'misc')
             mymydisp(isdisp,'   NB this directory may contain various secondary files produced by StabFem,');
             mymydisp(isdisp,'      such as flowfields projected after adaptation but not recomputed, adaptation masks, etc... ');
          end
        else
          mymydisp(isdisp,'     (list of base flows associated to newly computed meshes ; couples of .txt/.ff2m files )');
          mymydisp(isdisp,'     NB : these base flows are most likely simply projected and not recomputed, it is not recommended to use them')
          if length(thedir)==length(sfstats.MESHES)
              flag=0;
              %SF_core_log('w','WARNING : number of Meshes and Baseflows in directory MESHES differ !');
          end
        end
        mymydisp(isdisp,' ');
        metadata = SFcore_ImportData([SF_core_getopt('ffdatadir'), folder,'/',thedir(end).name],'metadataonly');
       
            thestring = [SFpad('Name',24),' | ',SFpad('Type',12), ' | ', SFpad('Date',20)];
            indexingtype = 'none';

        metadata = SFcore_ImportData([SF_core_getopt('ffdatadir'), folder,'/',thedir(end).name],'metadataonly');
        if isfield(metadata,'INDEXING')
            indexnames = fieldnames(metadata.INDEXING);
            for ind = indexnames'
                thestring = [thestring ,' | ', SFpad(ind{1},10)];
                if(imag(metadata.INDEXING.(ind{1}))~=0)
                    thestring = [thestring, blanks(6)];
                end
            end
        else
            indexnames = [];
        end            
        if ~strcmpi(folder,'DEBUG')
           thedir = nestedSortStruct(thedir, 'datenum') ; 
        end
        if length(thedir)>4
          rangetodisp = [1 2 -1 length(thedir)-1 length(thedir)];
           mymydisp(isdisp,['Total : ', num2str(length(thedir)) ' files. Displaying only first and last ones']);
        else
          rangetodisp = [1:length(thedir)];
        end
        mymydisp(isdisp,thestring);
        for i = rangetodisp
          if (i>0)
            name = thedir(i).name;
            date = thedir(i).date;
            metadata = SFcore_ImportData([SF_core_getopt('ffdatadir'), folder,'/',thedir(i).name],'metadataonly');
             if strcmp(indexingtype,'mesh')
                 if isfield(metadata,'meshfilename')
                    [~,meshfilename] = fileparts(metadata.meshfilename);
                 else
                    meshfilename = 'UNKNOWN';
                 end
                meshfilename = SFpad([meshfilename,'.msh'],17);
             elseif strcmp(indexingtype,'bf')&&isfield(metadata,'baseflowfilename')
                meshfilename = SFpad(metadata.baseflowfilename,30);
             else
                meshfilename = SFpad('(unknown)',16);
            end
            if isfield(metadata,'datatype')
                datatype = metadata.datatype;
            else
                datatype = 'unknown';
            end
            thestring = [ SFpad(name,24),' | ', SFpad(datatype,12), ' | ', SFpad(date,20) ];
           
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
             
%            sfstats.(folder)(i).filename = [SF_core_getopt('ffdatadir'), folder,'/', name]; 
            
            % adding metadata
            if isfield(metadata,'INDEXING')    
                fff = fieldnames(metadata.INDEXING);
                for jj =  1:length(fff)
                    ff = fff{jj};
%                    sfstats.(folder)(i).(ff) =metadata.INDEXING.(ff);
                end
            end
            
            %adding baseflowfilename
            if isfield(metadata,'baseflowfilename')  
%                sfstats.(folder)(i).baseflowfilename = metadata.baseflowfilename;
                bfmetadata = SFcore_ImportData(metadata.baseflowfilename,'metadataonly');
                % Iheriting metadata from mesh if relevant
                if isfield(bfmetadata,'INDEXING')
                  fff = fieldnames(bfmetadata.INDEXING);
                  for jj =  1:length(fff)
                    ff = fff{jj};
%                    sfstats.(folder)(i).(ff) =bfmetadata.INDEXING.(ff);
                  end
                end
            end
             
            
            %adding meshfilename
            if isfield(metadata,'meshfilename')  
%                sfstats.(folder)(i).meshfilename = metadata.meshfilename;
                meshmetadata = SFcore_ImportData(metadata.meshfilename,'metadataonly');
                % Iheriting metadata from mesh if relevant
                if isfield(meshmetadata,'INDEXING')
                  fff = fieldnames(meshmetadata.INDEXING);
                  for jj =  1:length(fff)
                    ff = fff{jj};
%                    sfstats.(folder)(i).(ff) =meshmetadata.INDEXING.(ff);
                  end
                end
            end
         else
            mymydisp(isdisp,'(skipping intermediate)    |')
         end

        end
      %if ~strcmpi(folder,'meshes')
     %   sfstats.(folder) = arrayofstructs2strucofarrays(sfstats.(folder));
     %   eventually this is useless !!!
      %end
      if ~strcmp(folder,'MESHES')
        mymydisp(isdisp,' ');
%        mymydisp(isdisp,' REMINDER : PROCEDURE TO RECOVER A FIELD FROM THIS DIRECTORY')
%        mymydisp(isdisp,' simply type the following command  (where index is the number of the desired field or keyword ''last'')');
%        mymydisp(isdisp,' ');
%        mymydisp(isdisp,['    object = SF_Load(''',folder,''',index)']);
%        mymydisp(isdisp,' ');
      end
     else
%         if ~isfield(sfstats,folder)
%             sfstats.(folder) = [];
%         end
       % mymydisp(isdisp,'#################################################################################');
       % mymydisp(isdisp,' ');
        SF_core_log('nnn',['.... NO DATA FILES FOUND IN DIRECTORY ', SF_core_getopt('ffdatadir'), folder]);
       % mymydisp(isdisp,' ');
     end
   try
   ifold = str2num(folder(end-6:end-1));
   ilast  = str2num(thedir(end).name(10:18));
   mymydisp(isdisp,[' To import one snapshot, use SF_Load. For instance to import last one : "Snap = SF_Load(''TimeStepping'',',num2str(ifold),',',num2str(ilast),')"']);
 catch
   mymydisp(isdisp,[' To import one snapshot, use SF_Load. (see manual) ']);
 end
 
   mymydisp(isdisp,'');
     
     end     

%%
function mymydisp(isdisp,string)
if(isdisp)
    disp(string);
end
end

function Nfiles = countfiles(directory,suffix)
  thedir = dir([directory,'/*',suffix]);
  Nfiles = length(thedir)
  if strcmp(suffix,'.msh')
    thedir = dir([directory,'/*_aux.msh']);
    Nfilesaux = length(thedir)
    Nfiles = Nfiles-Nfilesaux;
  end
end

function Snew = arrayofstructs2strucofarrays(S)
try 
 SF_core_log('d','converting array of structs to struct of arrays...');  
 thefields = fieldnames(S(1));
    for j=1:length(thefields)
        tt = [];
        for i=1:length(S)
            if isnumeric(S(i).(thefields{j}))
                tt(i) = S(i).(thefields{j});
            end
            if ischar(S(i).(thefields{j})) 
                tt{i} = S(i).(thefields{j});
            end
        end
        Snew.(thefields{j}) = tt;
    end
    S = Snew;
catch
    SF_core_log('w', 'error in arrayofstructs2strucofarrays : returning initial object');
    Snew = S;
end
end