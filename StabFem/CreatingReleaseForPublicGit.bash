# This script is to be executed each time you want to publish
# a stable release on the public gitlab repository

# first you have to delete branch master_beta from server

  cd ~
  git clone https://gitlab.com/stabfem/StabFem
  git clone https://gitlab.com/stabfem/StabFem_Develop
  cd StabFem
  git checkout -b master_beta
  cp -r -f ../StabFem_Develop/* .
  cp -r -f ../../StabFem_Develop/.gitlab-ci* .
  rm -rf PRIVATE_CASES
  rm -rf OBSOLETE_CASES
  rm -rf SOURCES_FREEFEM_PRIVATE/
  rm -rf PYSTABFEM_DEV/
  cp .gitlab-ci-autoindex-master-script.sh .gitlab-ci-autoindex-script.sh
  #git branch -D master_beta
  #git push origin master_beta

  git checkout -b master_beta
  git commit -m 'Release 3.7 (restarted from scratch for cleanup with [[PUBLISH]] and [[MANUAL]])'
  git remote add origin https://gitlab.com/stabfem/StabFem
  git push --set-upstream origin master_beta


## Pour recuperer dans une autre machine pour controle
# git clone https://gitlab.com/stabfem/StabFem
# cd StabFem
# git checkout master_beta
