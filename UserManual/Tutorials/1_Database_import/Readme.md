ContScout relies on a taxon-aware reference database that is used to tag individual proteins using a speed-optimized search tool (MMSeqs or DIAMOND). The "updateDB" tool, included in the software package handles all file import and pre-formatting steps. Public sequence databases from the Internet as well as user-provided local databases can be used as reference. 

**List of supported external databases:**
-nr (NCBI)  
-refseq (NCBI)  
-swissprot (NCBI, for testing only)  
-uniprotKB(EBI)   
-uniref90 (EBI)  
-uniref100 (EBI)  
-uniprotSP (EBI, for testing only)

**Install the software**  
*#create a working directory*  
>cd  
>mkdir CS_dir  
>cd CS_dir  
>  
>#install ContScout using one of the options below. Preferred one is "option c, singularity"  
>#a., Singularity, get pre-built package (recommended, assumed throughout the tutorial)
>mkdir ~/CS_dir/singularity_image
>cd ~/CS_dir/singularity_image
>singularity build contscout_latest.sif docker://h836472/contscout:latest
>cd ~/CS_dir/  
>
>#b., Docker, get pre-built package (recommended)    
docker pull h836472/contscout:latest
>  
>#c., Docker, compile for yourself (for experienced users, takes 40-60 minutes)    
>git clone https://github.com/h836472/ContScout.git  
>cd ContScout/DockerScript
>docker build ./ --tag contscout:demo
>  
>#d., install pre-requisites and scripts directly on your server (See User Manual, this option is not covered in the Tutorial)

**Set up databases**
>cd ~/CS_dir
>mkdir databases
>singularity run 
