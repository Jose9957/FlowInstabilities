function status = SFcore_Writeff2mFile(filename,varargin)
 
%
% This function writes a file in the .ff2m format
% USAGE :
%
%   SFcore_Writeff2mFile(filename,[opt1, var1] );
%   writes both string-valued data (keywords) and numerical data.
%   string-valued data are written on line 3 of the file.
%   numerical data are described on line 4 and writen in the sequel
%
%
% This program belongs to the StabFem project, freely distributed under GNU licence.
% copyright D. Fabre, 31 march 2019

%global verbosity;

% now only in ffdatadir 
filename = [SF_core_getopt('ffdatadir') filename];

if(mod(length(varargin),2)~=0)
    error('Error in SFcore_WriteFile : wrong number of arguments');
end
    
filedescription = '(no description provided when creating file)'; % default 
listkeywords = '';
listauxdata = '';
data = [];
for i = 1:length(varargin)/2
    description = varargin{2*i-1};
    if ~ischar(description)
        error(['Error in SFcore_WriteFile : wrong parameter number ', num2str(i+1)]); 
    end
    value = varargin{2*i};
    if isnumeric(value)
        if length(value)==1
            if imag(value)==0
                listauxdata  =  [listauxdata , 'real ',description, ' '];
                data = [ data value ];
            else
                listauxdata  =  [listauxdata , 'complex ',description, ' '];
                data = [ data, real(value), imag(value) ];
            end
        else
            error(['Error in SFcore_WriteFile : vectorial data not yet implemented']);
        end
    else
        if strcmpi(description,'filedescription')
            filedescription = value;
        else
            listkeywords = [listkeywords, ' ',description, ' ', char(value), ' ']; % NB char is for octave compatibility stuff
        end
    end
end

SF_core_log('d',['Function SFcore_Writeff2mFile.m : writing file ',filename]);
    
fid = fopen(filename,'w');
if fid<0
  SF_core_log('w',['Problem opening file ',filename]); 
  disp(['Problem opening file ',filename]); 
end

fprintf(fid,'%s\n','### This file belongs to the StabFem project (created by Driver SFcore_Writeff2mFile.m)');
fprintf(fid,'%s\n',filedescription);
fprintf(fid,'%s\n',listkeywords);
if ~isempty(listauxdata)
    fprintf(fid,'%s\n',listauxdata);
    fprintf(fid,'%f\n',data);
end
fclose(fid);

status = 1; % return value, to be improved ?

end
