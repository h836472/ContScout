**Summary**

ContScout is a software designed to identify and remove foreign sequences that appear in draft genomes as a consequence of contamination. The tool uses fast sequence lookup tools (MMSeqs or DIAMOND) to get taxonomical data for each predicted protein from a user-selected reference protein database (examples: uniprotKB, nr, refseq). As a major improvement over previous methods that rely on reference database and use a user-selected similarity threshold, ContScout applies a dynamic trimming on each hit list extracting the best-scoring hits that are most relevant when trying to classify proteins.
As an additional improvement, coding site spatial information from annotation (gff/gtf file) is used to calculate a consensus taxon call over assemby contigs / scaffolds. Then, all proteins from contigs / scaffolds with conflicting taxon information are marked from removal.  
  
__*Please note*__: with the current reference database taxon sampling, ContScout can only reliably differentiate between high level taxons, such as finding bacterial contamination in eukaryotes or identifying fungal contamination within plants. It is not designed for identifying contamination within a major eukaryote clade, such as identifying human contamination in an insect draft genome.  
For more information about the tool, please check out the ContScout manuscript under  
https://www.biorxiv.org/content/10.1101/2022.11.17.516887v1.  

**System requirements**

ContScout is written in R language. Both the code and the external apps it depends on are designed to run in a Unix/Linux environment and was tested on Linux, although with containerization (Docker, Singularity) running the tool should run on a machine with Windows / MacOS as well...  

External application as well as some ContScout components benefit from SMP multi-cpu machines and the system is written to automatically find the best vector instructions that the processor supports (avx2 >> sse4.1 >> sse2). ContScout requrires at least 128 GB of RAM and 500 GB of storage space but depending on the number of locally mirrored reference databases the storage footprint can easily reach 1-2 TB. There is a trade between allocated RAM and database search time where adding more RAM (256 GB, 512GB or 1 TB) significantly speeds up the database lookup step.

**Installation**

ContScout can be installed by
  
(1) natively, after manually installing all pre-requisites. (Not recommended, please contact the authors if you have to install the tool this way).  
(2) as a Docker image, locally built based on the docker file provided at GitHub (Recommended for advanced users / developers)  
* git clone https://github.com/h836472/ContScout.git
* cd ContScout/DockerScript/
* docker build ./ -t <your_container_tag>

(3) as a Docker / Singularity image, pulled from dockerhub (generally recommended installation method)  
* Docker: docker pull h836472/contscout:latest
* Singularity: singularity pull docker://h836472/contscout:latest
(as a result of singularity pull, *contscout_latest.sif* file is generated. I will later refer to this file as "<cs_sif_file>".

**Set up locally mirrored reference databases**

The ContScout package contains an automated database updater tool that fetches, labels and pre-formats public protein databases, such as refseq, nr or uniprotKB. Taxonomical labeling is based on the taxonomy database from NCBI.  
You can check the command line parameters of the tool from Docker / Singularity
* Docker: docker run h836472/contscout:latest updateDB -h
* Singularity: singularity exec <cs_sif_file> updateDB -h

Singularity example installing uniprotKB database, pre-formatted for both MMSeqs and Diamond lookups  
  
singularity exec -B <local_database_directory>:/databases -B <local_tmp_folder>:/cs_temp <singularity image> updateDB -u /databases --dbname uniprotKB -f MD -i https://github.com/h836472/ContScout/raw/main/DataBaseInfo/DB.info.txt"
  

Singularity example installing nr database, pre-formatted for MMSeqs lookups  
  
singularity exec -B <local_database_directory>:/databases -B <local_tmp_folder>:/cs_temp <singularity image> updateDB -u /databases --dbname nr_prot -f M -i https://github.com/h836472/ContScout/raw/main/DataBaseInfo/DB.info.txt"
  
__*Please note*__: While performing a protein database installation, updateDB also downloads the latest taxonomy database from NCBI.
  Public databases are ***huge***:, with compressed archives exceeding 50-80 GB. Depending on the network connection, download and the subsequent formatting steps will ***take several hours***.
  
 **Set up your own local reference database**
  
Currently, there is no automated solution to turn your local protein fasta file into a reference database. However, a small-scale "demo" database is available as an example for download at the GitHub repository under the Example folder and can be used as a guide regarding the file formats. 
First, it is recommended to download the latest NCBI taxonomy database by  
  
singularity exec -B <local_database_directory>:/databases contscout_latest.sif updateDB -u /databases --dbname ncbi_taxonomy -i https://github.com/h836472/ContScout/raw/main/DataBaseInfo/DB.info.txt

Then, please add the taxonomy information to the fasta headers of your reference file using the format below:  
  
\>***{Accession_Number}***:***t{TaxonID}***:***{HighLevelTaxonName}*** {Optional_description}  
\>***UniRef100_UPI00156F6715***:***t287***:***Bacteria*** major capsid protein n=1 Tax=Pseudomonas aeruginosa TaxID=287 RepID=UPI00156F6715  
  
Please use MMSeqs or DIAMOND to convert your reference database into search databases. (mmseqs createdb ... , DIAMOND makedb ...)
Copy the reference databases to your local database repository using the folder structure similar to the "demo" database provied as an example.
 
Then, reguster each of your custom databases by adding a new line in the *db_inventory.txt* file within your local database repository.
For manually added databases, the minimum required fields are "db.Name", "db.Loc", and "Format". Please check the *db_inventory.txt* file in the example set as a reference.

Later this year, a conversion tool, similar to updateDB, shall be released that automates user database addition.
  
**Running perform run ContScout**

In order to run the tool, you will need  
- a containerization environment, capable of running Docker images (Docker, Singularity, Shifter, etc)
- ContScout docker image (built locally with Docker using the source code at GitHub or downloaded directly from DockerHub)
- a query data folder, containing fasta protein file and gff / gtf annotation file (see demo data for example)
- a server computer with at least 500 GB storage and 128 GB RAM. (for big data sets 2TB+ storage and 512 GB+ RAM recommended)  
  
The following tutorial will guide you trough the analysis of an ultra-light example data set to be executed under Linux operating system using Singularity. The computational requirements for the demo set are marginal, it should run on a desktop / laptop computer.  

Steps
  
1., create a work directory with subfolders (change directory path according to your system)
  >mkdir /data/CS_test  
  >cd /data/CS_test  
  >mkdir local_database  
  >mkdir test_query  
  
  


