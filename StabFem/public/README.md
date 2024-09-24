Gitlab pages principles:

- To add your own case on the gitlab/pages StabFem website, you should do the following :
  1 - Create a Matlab/octave script for your case, 
  2 - add the tag [[PUBLISH]] in a comment line, anywhere in the script
  3 - commit/push on the server with tag [[PUBLISH]] in the commit message.


- Expanations on operation of the gitlab runner

  After each commit containing [[PUBLISH]], the two following scripts are run :
  
  * REPOROOT/.gitlab-ci-publish-script.sh
  	This script checks all scripts containing the [[PUBLISH]] tag, executes using matlab/publish those for 
  	which no valid content is found in the cache, a copies all "html" folders detected in the cache into
 	the "public" folder. 
 
  * REPOROOT/.gitlab-ci-autoindex-script.sh
 	Generation of the automatic index of the website in public/AutoIndex.html
 	
  *	The whole "public" folder is then uploaded to "https://stabfem.gitlab.io/StabFem/" or 
  "https://stabfem.gitlab.io/StabFem_Develop/" depending if you are on the public or private version of the project

- Generation of the front page :
This one is a static one, available as "public/index.html".
The layout of this page is based on the template "hyperspace" available at  https://html5up.net

 
NOTES: 

-   If you desire to modify the website sources locally, you may execute manually the scripts 
    .gitlab-ci-publish-script.sh and .gitlab-ci-autoindex-script.sh
    to recreate the whole website sources on your local environment.

-  To recreate only the autoindex without re-running everything: run a pipeline manually 
   from the gitlab interface with setting a variable "GENERATE_PAGE_ONLY" to "1" (or any other value)
 
VARIOUS TIPS:

- if your script contains the tag [[WORK]] then a copy of the "ffdatadir" directory will be put
on the StabFem server at adress /work/SF_works/(your case)/(ffdatafdir).tgz. You can use this for publishing
scripts in two stages : 1/ generate data and 2/ postprocess. See example "TEACHING_CASES/TP_UPS".

- to launch a specific set of autoruns : run a pipeline with specifyting VARIABLE : SFARVER with value "TOTO"
and your autoruns should condain the tag %%[[AUTORUN:TOTO]]
 
  
