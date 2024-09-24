
function [sfstats,flag] = SF_core_Status(sfstats,folder,isdisp)
  %% Function SF_core_Status

    flag=1;
     thedir = dir([SF_core_getopt('ffdatadir'), folder,'/*.txt']);    
     if ~isempty(thedir)
        mymydisp(isdisp,'#################################################################################');
        mymydisp(isdisp,' ');
        if ~strcmp(folder,'MESHES')
          mymydisp(isdisp,['.... CONTENT OF DIRECTORY ', SF_core_getopt('ffdatadir'), folder]);
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
        if isfield(metadata,'baseflowfilename')
            thestring = [' Index',' | ',SFpad('Name',17),' | ',SFpad('Type',12), ' | ', SFpad('Date',20),' | ', SFpad('BaseFlow file ',17)];
            indexingtype = 'bf';
        elseif isfield(metadata,'meshfilename')
            thestring = [' Index',' | ',SFpad('Name',17),' | ',SFpad('Type',12), ' | ', SFpad('Date',20),' | ', SFpad('Mesh file ',17)];
            indexingtype = 'mesh';
        else
            thestring = [' Index',' | ',SFpad('Name',17),' | ',SFpad('Type',12), ' | ', SFpad('Date',20),' | ', SFpad('(no bf or mesh indication)',17)];
            indexingtype = 'none';
        end
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
        mymydisp(isdisp,thestring);
        if ~strcmpi(folder,'DEBUG')
           thedir = nestedSortStruct(thedir, 'datenum') ; 
        end
        for i = 1:length(thedir)
            name = thedir(i).name;
            date = thedir(i).date;
            try 
                metadata = SFcore_ImportData([SF_core_getopt('ffdatadir'), folder,'/',thedir(i).name],'metadataonly');
            catch
                SF_core_log('w',['in SF core status : failed to read file ',thedir(i).name]);
                metadata = [];
            end
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
            thestring = [' ',SFpad(num2str(i),5),' | ', SFpad(name,16),' | ', SFpad(datatype,12), ' | ', SFpad(date,20),' | ', meshfilename ];
           
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
             
            sfstats.(folder)(i).filename = [SF_core_getopt('ffdatadir'), folder,'/', name]; 
            
            % adding metadata
            if isfield(metadata,'INDEXING')    
                fff = fieldnames(metadata.INDEXING);
                for jj =  1:length(fff)
                    ff = fff{jj};
                    sfstats.(folder)(i).(ff) =metadata.INDEXING.(ff);
                end
            end
            
            %adding baseflowfilename
            if isfield(metadata,'baseflowfilename')  
                sfstats.(folder)(i).baseflowfilename = metadata.baseflowfilename;
                bfmetadata = SFcore_ImportData(metadata.baseflowfilename,'metadataonly');
                % Iheriting metadata from mesh if relevant
                if isfield(bfmetadata,'INDEXING')
                  fff = fieldnames(bfmetadata.INDEXING);
                  for jj =  1:length(fff)
                    ff = fff{jj};
                    sfstats.(folder)(i).(ff) =bfmetadata.INDEXING.(ff);
                  end
                end
            end
             
            
            %adding meshfilename
            if isfield(metadata,'meshfilename')  
                sfstats.(folder)(i).meshfilename = metadata.meshfilename;
                meshmetadata = SFcore_ImportData(metadata.meshfilename,'metadataonly');
                % Iheriting metadata from mesh if relevant
                if isfield(meshmetadata,'INDEXING')
                  fff = fieldnames(meshmetadata.INDEXING);
                  for jj =  1:length(fff)
                    ff = fff{jj};
                    sfstats.(folder)(i).(ff) =meshmetadata.INDEXING.(ff);
                  end
                end
            end
        end
        % added nov 2021 : manage binary + vtk + vtu files
        thedir = dir([SF_core_getopt('ffdatadir'), folder]);       
        AA = {thedir.name};
        if sum(contains(AA,'.btxt'))
            mymydisp(isdisp,'##  Binary data files detected in this folder');
        end
        AA = {thedir.name};
        if sum(contains(AA,'.vtu'))
            mymydisp(isdisp,'##  VTU data files detected in this folder');
        end
        AA = {thedir.name};
        if sum(contains(AA,'.vtk'))
            mymydisp(isdisp,'##  VTK data files detected in this folder');
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