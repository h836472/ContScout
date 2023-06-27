ContScout relies on a taxon-aware reference database that is used to tag individual proteins using a speed-optimized search tool (MMSeqs or DIAMOND). The "updateDB" tool, included in the software package handles all file import and pre-formatting steps. Public sequence databases from the Internet as well as user-provided local databases can be used as reference. 

List of supported external databases:
-nr (NCBI)  
-refseq (NCBI)  
-swissprot (NCBI, for testing only)  
-uniprotKB(EBI)   
-uniref90 (EBI)  
-uniref100 (EBI)  
-uniprotSP (EBI, for testing only)

To save time on the, we will download the "swissprot" database from NCBI but please remember: this is a small, human-curated database with extremely week taxon representation. Real analysis should not be performed with this database or the EBI-provided uniprotSP.

>#get to your home directory, create a working directory
>cd
>mkdir CS_dir
>cd CS_dir
>#install ContScout using one of the options below. Preferred one is "option c, singularity"
>#a. Docker, compile for yourself (experienced user, takes 40-60 minutes),
>git clone https://github.com/h836472/ContScout.git
>cd ContScout/DockerScript
>


updateDB -u <user_folder> -n <database_name>
