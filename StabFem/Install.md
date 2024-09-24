
## Requirements :

- Ubuntu 18, Mac OS 10.10+, Windows 10  (may work on other systems but not tested)

- Mablab (2017b or more recent) or Octave (5.0 or more recent)

- FreeFem++ (4.4 or more recent)

- Some of the more advanced examples require SLEPC. In this case it is recommended to install
FreeFem++ starting from gitlab sources rather than a precompiled version


## Download 

- from the front page of the gitlab repositpry website, click "clone".

- alternatively from command line: 

```
git clone https://https://gitlab.com/stabfem/StabFem
```

## Installation settings (optional) 


- In your configuration file set the path of the FreeFem++ executables as follows

```
export SF_FREEFEM_ROOT="xxx"  # ("xxx" may be "/usr/local/bin" or something else depending on your installation)
```

(NB this step is optional and the drivers may find the relevant path automatically, but recommended for best operation)

- For best performance of some plotting features, you may compile the mex 

## Usage 

Simply open one of the .m programs of the project with Octave or Matlab and run it !





