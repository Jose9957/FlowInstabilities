function res = SFcore_AddMESHFilenameToFF2M(file,meshfilename,bffilename)

SF_core_log('d','### entering SFcore_AddMESHFilenameToFF2M')

if SF_core_getopt('isoctave')
  SF_core_log('d','debugging SFcore_AddMESHFilenameToFF2M with octave')
  %return
end

if (nargin<3)
    bffilename = '';
end

if ~isempty(strfind(file,'.txt'))||~isempty(strfind(file,'.msh')) % NB contains is better but not available with octave !
    file = [file(1:end-4), '.ff2m'];
end

% Read txt into cell A
%fid = fopen([SF_core_getopt('ffdatadir'),file],'r')

if ~exist(file,'file')
  file = [SF_core_getopt('ffdatadir'),file];
  if ~exist(file,'file')
    SF_core_log('e',['could not open file ',file, ' in SFcore_AddMESHFilenameToFF2M']);
  end
elseif exist(file,'file') && contains(file,'/')
   SF_core_log('d', 'file seems to be provided with whole path')  
else
    SF_core_log('w',['in SFcore_AddMESHFilenameToFF2M : File ',file ,' exists in root directory ! this may lead to incorrect behavior']); 
end

% Read first 3 lines

fid = fopen(file,'r');
i = 1;
tline = fgetl(fid);
A{i} = tline;
while ischar(tline)&&i<4
    i = i+1;
    tline = fgetl(fid);
    A{i} = tline;
end


% If meshfilename already present, stop here !  

if length(A)>2&&contains(A{3},'meshfilename')
    if contains(A{3},meshfilename)
        SF_core_log('l',' in SFcore_AddMESHFilenameToFF2M : "meshfilename" is already present and correct');
        fclose(fid);
        return;
    else
        SF_core_log('l',' in SFcore_AddMESHFilenameToFF2M : "meshfilename" has changed and will be rewritten ');
    end
end
% otherwise continue

% Changes third line

A{3} = [ A{3}, ' meshfilename ',meshfilename];
%t = A{3}
if ~isempty(bffilename)
    A{3} = [ A{3}, ' baseflowfilename ',bffilename];
end

% reads next lines
while ischar(tline)
    i = i+1;
    tline = fgetl(fid);
    A{i} = tline;
end
fclose(fid);


% Writes back the file

fid = fopen(file, 'w');
for i = 1:numel(A)
    if A{i+1} == -1
        fprintf(fid,'%s', A{i});
        break
    else
        fprintf(fid,'%s\n', A{i});
    end
end
fclose(fid);

SF_core_log('d',[' added meshfilename ',meshfilename,' to file ',file]);

res = 0;

SF_core_log('d','### LEAVING SFcore_AddMESHFilenameToFF2M')


end
