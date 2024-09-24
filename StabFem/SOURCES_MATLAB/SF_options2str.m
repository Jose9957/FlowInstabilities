function arg = SF_options2str(options)
% This function transforms a list of options, passed as either a 
% a options-array of descriptor-value pairs or a structure, into a string
% of optional parameters to be used by your Freefem solver.

if ischar(options)
    SF_core_log('dd','Arguments passed as a string...')
    arg = options;
elseif iscell(options)
    SF_core_log('dd','Arguments passed as a options-array...')
    if mod(length(options),2)==1
        SF_core_log('e', 'must provide a list of pairs descriptor/value')
    end
    numel = length(options)/2;
    arg = ' ';
    for i=1:numel
        if ~ischar(options{2*i-1})
            SF_core_log('e','In argument : descriptors must be char type')
        end    
        arg = [ arg, '-',options{2*i-1}];
        if ischar(options{2*i})
             arg = [ arg, ' ', options{2*i},' '];
        elseif isnumeric(options{2*i})
            if imag(options{2*i})==0
                arg = [ arg, ' ', num2str(options{2*i}),' '];
            else
                arg = [ arg,'_r ', num2str(real(options{2*i})),' ',arg,'_i ', num2str(imag(options{2*i})),' '];
            end
        else
            SF_core_log('e','In argument : value must be char or numeric')
        end
        if strcmp(options{2*i-1},'nev')||strcmp(options{2*i-1},'shift')
             SF_core_log('w',' Arguments nev and shift should not be passed as part of ''Options'' but directly');
        end
    end
elseif isstruct(options)
     SF_core_log('dd','Arguments passed as a structure...');
     arg = ' ';
     fffield = fieldnames(options);
     for i = 1:length(fffield)
         field = fffield{i};
         arg = [ arg, ' -',field, ' '];
         if isnumeric(options.(field))&&length(options.(field))==1 
           arg = [ arg, num2str(options.(field)), ' ']; 
         elseif ischar(options.(field)) 
            arg = [ arg, options.(field), ' '];
         else
             SF_core_log('e',['bad value for field ',field, ' in options ']);
         end
         if strcmp(field,'nev')||strcmp(field,'shift')
             SF_core_log('w',' Arguments nev and shift should not be passed as part of ''Options'' but directly');
         end
     end
else
    SF_core_log('e', ' Field "Option" must be char, options or struct');
end
    
end