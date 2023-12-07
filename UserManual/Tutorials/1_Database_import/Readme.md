ContScout relies on a taxon-aware reference database that is used to tag individual proteins using a speed-optimized search tool (MMSeqs or DIAMOND). The "updateDB" tool, included in the software package handles all file import and pre-formatting steps. Public sequence databases from the Internet as well as user-provided local databases can be used as reference. 

**List of supported external databases:**  
-nr (NCBI)  
-refseq (NCBI)  
-swissprot (NCBI, for testing / tutorial purposes only)  
-uniprotKB(EBI)   
-uniref90 (EBI)  
-uniref100 (EBI)  
-uniprotSP (EBI, for testing / tutorial purposes only)

**Set up reference databases - test with swissprot**

Prerequisite: please install ContScout. Consult the user manual for more details.  

>mkdir ~/CS_dir  
>cd ~/CS_dir  
>mkdir databases  
>singularity run ~/CS_dir/singularity_image/contscout_latest.sif updateDB -u ~/CS_dir/databases -d swissprot

If you have less than 500 GB free space in your project directory, the tool will quit with error. For testing, you can disable this test by adding the -f (--force) flag to the command. Using this flag while setting up a real database is not recommended.

>singularity run ~/CS_dir/singularity_image/contscout_latest.sif updateDB -u ~/CS_dir/databases -f -d swissprot  

Please note that even the demo / swissprot database creation will take several minutes to complete. Comprehensive databases, such as nr, refseq, uniprotKB will take several hours to download and pre-format.

**Set up reference databases - import a custom database from a local file**

Users have the option to import their own custom database from a local file. To enable this feature, a fasta file and a matching taxonomy mapping file need to be created.

**Fasta format example: (file:customDB.fasta)**  
\>P69739|MBHS_ECOLI
MNNEETFYQAMRRQGVTRRSFLKYCSLAATSLGLGAGMAPKIAWALENKPRIPVVWIHGL
ECTCCTESFIRSAHPLAKDVILSLISLDYDDTLMAAAGTQAEEVFEDIITQYNGKYILAV
EGNPPLGEQGMFCISSGRPFIEKLKRAAAGASAIIAWGTCASWGCVQAARPNPTQATPID
KVITDKPIIKVPGCPPIPDVMSAIITYMVTFDRLPDVDRMGRPLMFYGQRIHDKCYRRAH
FDAGEFVQSWDDDAARKGYCLYKMGCKGPTTYNACSSTRWNDGVSFPIQSGHGCLGCAEN
GFWDRGSFYSRVVDIPQMGTHSTADTVGLTALGVVAAAVGVHAVASAVDQRRRHNQQPTE
TEHQPGNEDKQA  
  
**Taxon mapping file example: (file:customDB.tax)**  
P69739|MBHS_ECOLI\t83333  

Example:

>mkdir ~/CS_dir 
>cd ~/CS_dir  
>mkdir customDB  
>cd ~/CS_dir/customDB  
>wget -c https://github.com/h836472/ContScout/raw/main/UserManual/Tutorials/TutorialExampleData/demoDB_for_import.tar.gz   
>tar -xvf demoDB_for_import.tar.gz   
>singularity run ~/CS_dir/singularity_image/contscout_latest.sif updateDB -u ~/CS_dir/databases -d custom\:demoDB\:\~/CS_dir/customDB/demoDB.fasta
  
If you have less than 500 GB free space in your project directory, the tool will quit with error. For testing, you can disable this test by adding the -f (--force) flag to the command. Using this flag while setting up a real database is not recommended.
>singularity run ~/CS_dir/singularity_image/contscout_latest.sif updateDB -u ~/CS_dir/databases -d custom\:demoDB\:\~/CS_dir/customDB/demoDB.fasta -f

You can list all installed databases under a user directory with the following commands.
>singularity run ~/CS_dir/singularity_image/contscout_latest.sif updateDB -u ~/CS_dir/databases -l
