function [] = mydisp(verbositylevel, string)
 verbosity = SF_core_getopt('verbosity')-1;

%global ff ffdir ffdatadir sfdir verbosity
if (verbosity >= verbositylevel)
    disp([blanks(verbositylevel), string])
end
end