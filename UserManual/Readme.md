**Summary**

ContScout is a software designed to identify and remove foreign sequences that appear in draft genomes as a consequence of contamination. The tool uses fast sequence lookup tools (MMSeqs or DIAMOND) to get taxonomical data for each predicted protein from a user-selected reference protein database (examples: uniprotKB, nr, refseq). As a major improvement over previous methods that rely on reference database and use a user-selected similarity threshold, ContScout applies a dynamic trimming on each hit list extracting the best-scoring hits that are most relevant when trying to classify proteins.
As an additional improvement, coding site spatial information from annotation (gff/gtf file) is used to calculate a consensus taxon call over assemby contigs / scaffolds. Then, all proteins from contigs / scaffolds with conflicting taxon information are marked from removal.  
  
__*Please note*__: with the current reference database taxon sampling, ContScout can only reliably differentiate between high level taxons, such as finding bacterial contamination in eukaryotes or identifying fungal contamination within plants. It is not designed for identifying contamination within a major eukaryote clade, such as identifying human contamination in an insect draft genome.  
For more information about the tool, please check out the ContScout manuscript under  
https://www.biorxiv.org/content/10.1101/2022.11.17.516887v1.  

**System requirements**

ContScout is written in R language. Both the code and the external apps it depends on are designed to run in a Unix/Linux environment and was tested on Linux, although with containerization (Docker, Singularity) running the tool should run on a machine with Windows / MacOS as well...  

External application as well as some ContScout components benefit from SMP multi-cpu machines and the system is written to automatically find the best vector instructions that the processor supports (avx2 >> sse4.1 >> sse2). ContScout requrires at least 128 GB of RAM and 500 GB of storage space but depending on the number of locally mirrored reference databases the storage footprint can easily reach 1-2 TB. There is a trade between allocated RAM and database search time where adding more RAM (256 GB, 512GB or 1 TB) significantly shortens the database lookup step.

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

Singularity example about installing uniprotKB database, pre-formatted for both MMSeqs and Diamond lookups  
  
singularity exec -B <local_database_directory>:/databases -B <local_tmp_folder>:/cs_temp <singularity image> updateDB -u /databases --dbname uniprotKB -f MD -i https://github.com/h836472/ContScout/raw/main/DataBaseInfo/DB.info.txt"
  
__*Please note*__: While performing a protein database installation, updateDB also downloads the latest taxonomy database from NCBI.
  Public databases are __*huge*__:, with compressed archives exceeding 50-80 GB. Depending on the network connection, download and the subsequent formatting steps will take several hours.
  
 **Set up your own local reference database**
  
Currently, there is no automated solution to turn your local protein fasta file into a reference database. However, a small-scale "demo" database is available for download as part of the GitHub package to guide you trough the format. 
  First, it is recommended to download the latest NCBI taxonomy database by  
  
singularity exec -B <local_database_directory>:/databases <singularity image> updateDB -u /databases --dbname ncbi_taxonomy -i https://github.com/h836472/ContScout/raw/main/DataBaseInfo/DB.info.txt"


