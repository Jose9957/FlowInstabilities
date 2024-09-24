### Instructions on how to PUBLISH your work on the Stabfem website


Once you have written a .m code which you have validated with Matlab / Octave,
you can publish on the StabFem website through the following procedure :

1. Add the following line anywhere in your program 
```
% [[PUBLISH]]
```

2. Commit your file and push it to the stabfem server, witgh a tag [[PUBLISH]] in the commit message

Your program will be executed on the StabFem server and the result will be published on the website.

Normally your program should appear in the automatic index 
[here](https://stabfem.gitlab.io/StabFem_Develop/newwebsite/index.html)
(or [here](https://stabfem.gitlab.io/StabFem_Develop/newwebsite/index.html) for private version of the project )

## Advices when preparing your programs for publishing

- "Blocks" begin by %% , and the sections of comments at the beginning of each block are interpreted 
(see Matlab documentation on publishing markup to see what is recognized).
Note that latex code is recognized

```
%%
%  Now we solve $\partial^2 F/ \partial x^2 = 1$
%
```

- A title can be inserted in each block and a table of contents will be generated. For this your title
should appear after the %% 

```
%% Chapter 2 : we adapt the mesh...
%  isn't it cool ???
```

- If first line begins with %% then a general title (Orange)

- for proper operation %% and % mush be followed by a blank space 

- Verbosity should normally be set to 2 or 3 in publish mode.
  If your program mentions verbosity=4 it will automatically set to 3.
  If you really want to show details on execution (including freefem output) set verbosity=5.
 

## How does it work and how to follow what the server has done ?

- Generation of htlm content from the .m programs is done by the script  .gitlab-ci-publish-script.sh 

- Generation of automatic index by script .gitlab-ci-autoindex-script.sh

To access the execution logs of these scripts you can go 
[there](https://gitlab.com/stabfem/StabFem_Develop/-/pipelines/)

The jobs run each time you push to the repository and your commit message contains [[PUBLISH]].

You can also lauch manually by running a pipeline [here](https://gitlab.com/stabfem/StabFem_Develop/-/pipelines/new).
For this specify a *Variable* With key *GENERATE_PAGE* and value *1*.

You can also launch only the second part of the job (generation of autoindex without regeneration of html from .m) by specifying a *Variable* With key *GENERATE_PAGE_ONLY* and value *1*.





