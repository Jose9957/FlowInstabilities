%> @file SOURCES_MATLAB/SF_core_detectlib.m
%> @brief Matlab function detecting whether the FreeFem++ installation
%includes some librairies (i.e. MUMPS).
%>
%> Usage: results = SF_core_detectlib(libname)
%> @param[in] libname : library name (i.e. "MUMPS_seq")
%> @param[out] results : logical value, true if library available
%>
%> @author Maxime Pigou
%> @version 1.0
%> @date 25/10/2018 Start writing version 1.0

function results = SF_core_detectlib(libname,varargin)

p = inputParser;
addParameter(p, 'bin', 'default', @ischar);
parse(p, varargin{:});

% Testing libname
if ~ischar(libname) || size(libname,1)~=1
    SF_core_log('w',['Incorrect tested library name, returned false ' ...
        'value at library detection but please check the expected name.']);
    results = false;
    return;
end

% Generating random string for file name

%fn = sprintf('%s.edp', SF_core_file('mktmpfile'))
fn = ['test_detectlib_',libname,'.edp'];

%try
    % Writing library load command into EDP file
    fh = fopen(fn,'w');
    fprintf(fh, 'load "%s"\n',libname);
    fclose(fh);

    % Executing FreeFem++ on the EDP file to check compilation
    status = SF_core_freefem(fn,'continueonerror',true,'showerrormessage',false,'bin',p.Results.bin);
    
    % Deleting file
    SF_core_syscommand('rm',fn);
    
    % Return result
    results = status==0;

%catch
 %   SF_core_log('w',['SF_core_detectlib: Unexpected error while ' ...
 %       'detecting the presence of ' libname '. Returning false by ' ...
 %       'default.']);
 %   results = false;
  %  return;
%end
end