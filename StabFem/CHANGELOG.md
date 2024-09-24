# List of novelties for StabFem project (this log file was started with version 3.9)


## Version 3.10 (28/01/2022)

- The [manual](https://gitlab.com/stabfem/StabFem/-/jobs/artifacts/master/file/99_Documentation/MANUAL/main.pdf?job=makepdf) has been updated. In particular, Chapter 4 "advanced drivers for flow instability problems" explains 
all the "secret tricks" which make StabFem particulary powerful for parametric studies of flow instability
(spectum explorator, threshold tracker, continuation mode, etc...)

- A new method to set the default solvers and the default plotting options for basflows and eigenmodes 
has been introduced (see manuel)

- A script reproducing sample results from a recenlty paper has been added in the "PUBLICATION_CASES" section: 
  Stability and dynamics of the flow past of a bullet-shaped blunt body moving in a pipe
  P. Bonnefis, D. Fabre, C. Airiau (submitted to JFM)
  See the paper in [Arxiv :](https://arxiv.org/abs/2112.08730)
  See the [script](https://stabfem.gitlab.io/StabFem//BLUNTBODY_IN_PIPE/SCRIPT_SampleResult.html)

This script demonstrates most of the novelties explained above. Have a look!

- New types of adaptation masks (ellipse and trapeze in addition to rectangle).
See example [here](https://stabfem.gitlab.io/StabFem//EXAMPLE_Lshape/Demo_Masks.html)

- Again improvements in TimeStepping drivers. See manual.

- Default colormap is now VIRIDIS instead of JET.
If you want to understand why VIRIDIS is so good, ask Francesco ! 
He will prepare you a good espresso and explain you all the virtues of VIRIDIS.


## Version 3.9 (08/01/2021)

1/ Website :
   a/ The autoindex page now has a new category entitled « latest publications » which regroups the content added in the past 15 days.
       Your next contributions will be highlighted. Looking forward for them !
   b/ If your script contains the tag [[WORK]] then the database directory is kept as a « cache » on the server of the project.
   c/ If a script begins by SF_RecoverDataBase('WORK’) then the corresponding database folder is recovered from the cache of the server
      (Or alternatively from a location  like  /work/SF_works/(mycase)/WORK.tgz ;  If you have logged to the server and put a zipped file in such a location)
     This can be very useful to split your published scripts in several parts (for instance a first one for computations and a second one for post-processing)

2/ Improvement of metadata management.
	- metadata can now be defined for the mesh ( through a macro SFWriteMesh defined in SF_Custom.idp) and appear in the index.
        - baseflows inherit metadata from the mesh -> check sfs = SF_Status; sfs.BASEFLOWS
        - eigenvalues inherit metadata from the mesh and the baseflow -> check sfs.EIGENVALUES
        - new option ’Threshold’ in SF_Stability : SF_Stability([…],’Threshold’,’single’) : detects if lambda_r changes sign between the last call and the current one;
          if so deduces the threshold by interpolation and store the properties (including all metadata) in database -> check sfs.THRESHOLDS
          NB option SF_Stability([…],’Threshold’,’multiple’) should do the same and detects thresholds on secondary branches in addition to the leading one. To be tested.
  REMARK : To benefit from all these it is required to modify your stability solvers to generate a file Spectrum.ff2m explaining the content of Spectrum.txt (see how this is done in Stab_2D.edp)

3/ Improved the integration of parallel solvers. See examples on website.

4/ New syntax and options for database management.
   SF_DataBase(’create’,‘WORK’). -> for SF_core_setopt(‘ffdatadir’,’WORK’) ;  SF_core_arborescence(‘cleanall’)
   SF_DataBase(‘Index’) -> for SF_Status
   SF_DataBase(‘rm’,’BASEFLOWS’, [1:5]) -> partial cleanup of the database

5/ SFverb(4) : new shortcut for SF_core_setopt(‘verbosity’,4)  

6/ Redesign of interface files : 
   a/ now at each launch of FreeFem an automatically generated file SF_AutoInclude.idp  (previously called SF_VersionDependent.idp)  is included in the header of your programs.
	This file contains in particular the database directory name ffdatadir (previously in workdir.pref). 
	You can also directly specify some lines to include in this file :
	SF_Launch(‘mysolver.edp’,’Include’,{‘load MUMPS’,’ macro my macro() 1 \\EOM’})
  b/ list of fe-spaces to recognize for plotting are now managed as follows : 
	SF_core_setopt('VhList','P2,P2P2P1,P1bP1bP1’)
	  ( replacing macro STORAGEMODES in SF_Custom.idp )
  c/ A consequence of those novelties, it is no longer mandatory to have a file SF_Custom.idp !
    If present, this file should only contain customizable macros such as SFWriteBaseFlow, etc...
