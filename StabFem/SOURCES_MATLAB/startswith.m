% Check if a string starts with a given prefix
% Returns 1 if s starts with prefix, 0 else
%
% NB this function exists in matlab as startsWith but not in octave !!!

function retval = startswith(s, prefix)
  n = length(prefix);
  if n == 0 % Empty prefix
    retval = 1; % Every string starts with empty prefix
    return
  end
  retval = strncmp(s, prefix, n);
end