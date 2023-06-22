**Summary**

ContScout is a software designed to identify and remove foreign sequences that appear in draft genomes as a consequence of contamination. The tool uses fast sequence lookup tools (MMSeqs or DIAMOND) to get taxonomical data for each predicted protein from a user-selected reference protein database (examples: uniprotKB, nr, uniref). With the current version, ContScout performs taxon call for each query sequences at multiple taxon levels (superkingdom, kingdom, phylum, class, order and family). In addition to the taxon label, a vote weight (between 1.0 and 2.0) is added, depending on the number of top-scoring consecutive hits that back up the taxon call. Based on the user-provided annotation file (gff/gtf file), proteins are grouped according according to assembled contigs / scaffolds and individual taxon votes are summed to yield a consensus taxon call for each contig / scaffolds. At each taxon level, contigs with taxon label not matching the expected lineage of the query genome are marked for removal, together with all coded proteins.
  
__*Please note*__: Reference database taxon sampling has a big effect on ContScout ability to separate a contaminant from a closely related host. If both genomes have at least a few close representatives from the same family, ContScout is expected to accurately distinguish contamination from host proteins. However, for a sparsely sampled query, analysis at finer taxonomic resolution (family, order) might not be feasible. The program has excessive diagnostic capabilities to inform the users about potentially conflicting situations at which the results need to be handled with care. (see examples below) 

**System requirements**

ContScout is written in R language. Both the code and the external apps it depends on are designed to run in a Unix/Linux environment and was tested on several Linux distributions (Ubuntu, Debian, CentOS), although with the containerization (Docker, Singularity) running the tool should be possible on a machine with Windows / MacOS as well...  

External application as well as some ContScout components benefit from SMP multi-cpu machines and the system is written to automatically find the best vector instructions that the processor supports (avx2 >> sse4.1 >> sse2). Due to working with huge databases, ContScout requrires at least 128 GB of RAM and 500 GB of storage space but depending on the number of locally mirrored reference databases the storage footprint can easily reach several TeraBytes. There is a trade between allocated RAM and database search time where adding more RAM (256 GB, 512GB or 1 TB) significantly speeds up the database lookup step. Typical installation time for the tool from Dockerfile is less then an hour. Typical database setup for "test" (swissprot, tutorial) databases is a matter of minutes, while "real" databases take several hours to download and pre-format before analysis. Runtime for a typical eukaryote genome is between 1 and 2 hours on a 24-core server / workstation computer.

**Installation**

ContScout can be installed by
  
(1) natively, by downloading the two main scripts "updateDB" and "ContScout" after manually installing all pre-requisites. Please note that this is not recommended although authors can provide help with the local installation if needed. 
Pre-requisites for a native installation
* python 3.x  
* java (tested with openJDK 17)  
* curl, wget tools  
* R programming language (tested with v4.1.2)
* several R packages (optparse, bitops, Biostrings, rtracklayer, rlang, GenomicRanges, WriteXLS, googlesheets4)
* NCBI blast (for importing NCBI databases. Tested with 2.12.0+)
* awk
* DIAMOND (tested with v2.1.8)  
* MMSeqs (tested with version "25688290f126d7428155ad817e9809173fe78afd")
* jacksum (tested with v3.5.0) 

(2) as a Docker image, locally built based on the docker file provided at GitHub (Recommended for advanced users / developers)  
* git clone https://github.com/h836472/ContScout.git
* cd ContScout/DockerScript/
* docker build ./ -t <your_container_tag> --build-arg CACHEBUST=$(data+%s)
Please allow 40-60 minutes of compilation time.

(3) as a Docker / Singularity image, pulled from dockerhub (generally recommended installation method)  
* Docker: docker pull h836472/contscout:latest
* Singularity: singularity pull docker://h836472/contscout:latest
(as a result of singularity pull, *contscout_latest.sif* file is generated. I will later refer to this file as "<cs_sif_file>".

**Set up locally mirrored reference databases**

The ContScout package contains an automated database updater tool called "updateDB" that fetches, labels and pre-formats public protein databases, such as uniref, nr or uniprotKB. Taxonomical labeling is based on the taxonomy database from NCBI.  
You can check the command line parameters of the tool from Docker / Singularity
* Docker: docker run h836472/contscout:latest updateDB -h
* Singularity: singularity exec <cs_sif_file> updateDB -h

**Command line options for updateDB**
-u / --userdir #User directory. This is the location to store the local database copy.
-t / --tempdir #Directory to write temporary files while installing a database.
-l / --list_databases #Prints a summary on the console about nstalled databases found in the user directory.
-d / dbname #database to be downloaded (nr, uniref,uniprotKB, or custom)
-i / info #database descriptor file with links to public sequence databases. Currently points to https://docs.google.com/spreadsheets/d/1_FPaAnyHVUhHzV8gwic2X3RKaN9vSl9jcTN_50T7X24

See tutorials on how to import reference databases, including the option to use custom local sequence files.
Singularity example installing swissprot database (for testing only, not recommended for real analysis)
  
>singularity exec -B <local_database_directory>:/databases -B <local_tmp_folder>:/tmp <singularity image> updateDB -u /databases --dbname swissprot 
  
__*Please note*__: While performing a protein database installation, updateDB also downloads the latest taxonomy database from NCBI, that will be bound to the reference database.
  Public databases are ***huge***:, with compressed archives exceeding 50-80 GB. Depending on the network connection, download and the subsequent formatting steps will ***take several hours***.
 
**Running ContScout**

In order to run the tool, you will need  
- a containerization environment, capable of running Docker images (Docker, Singularity, Shifter, etc)
- ContScout docker image (built locally with Docker using the source code at GitHub or downloaded directly from DockerHub)
- a query data folder, containing fasta protein file and gff / gtf annotation file (see demo data for example)
- a server computer with at least 500 GB storage and 128 GB RAM. (for big data sets 2TB+ storage and 512 GB+ RAM recommended)  
  
The following short example will guide you trough the analysis of an ultra-light example data set to be executed under Linux operating system using Singularity. The computational requirements for the demo set are marginal, it should run on any desktop / laptop computer.  

Steps
  
1., create a work directory (change directory path according to your system)
  >mkdir /data/CS_test  
  >cd /data/CS_test  
  
 2., download and extract the database as well as the draft genome file for the tutorial
 >wget https://github.com/h836472/ContScout/raw/main/Example/databases.tar.gz  
 >tar -xvf databases.tar.gz  
 >rm databases.tar.gz  
 >wget https://github.com/h836472/ContScout/raw/main/Example/query.tar.gz  
 >tar -xvf query.tar.gz  
 >rm query.tar.gz   

Please take some time to familiarize yourself with the organization of the local repository database (file ***databases/db_inventory.txt*** and database subfolders) and especially with the layout of the query data (***query/Quersube***).   
Your input files shall be copied in a single query directory  (***query/Quersube/***) with the protein fasta copied under "FASTA_prot" and the annotation file copied under "GFF_annot" subfolder, respectively. Both gzip-comressed and uncompressed fasta and gff/gtf files are accepted.  
 
3., Download and prepare ContScout image for Singularity  
>mkdir singularity_images  
>cd singularity_images  
>singularity pull docker://h836472/contscout:latest  
>cd ..  
 
4., Start ContScout via a Singularity call
>singularity exec -B /data/CS_test/databases:/databases -B /data/CS_test/query:/query -B /tmp:/tmp /data/CS_test/singularity_images/contscout_latest.sif ContScout -u /databases -i /query/Quersube -q 58331 -c 2 -x all -p 20 -t /tmp -d demo -a mmseqs

Please notice the singularity "bind directory" commands, that are written in ***-B host:guest*** format. Each of them adds an existing host directory to the ContScount container with the guest directory name as specified. It is recommended, that singularity bind parameters are carefully matched with ContScout parameters. For an example see ***-B /tmp:/tmp singularity*** later parameter followed by ContScout parameter ***-t /tmp***.
 
  When ready, ContScout creates an output directory within the folder that was specidied by the user via the -i parameter. Output folder follows the following scheme: ***{species\_latin\_name}\_tax\_{taxonID}\_{timestamp}***. Example: ***Quercus\_suber\_tax\_58331\_13Jan_2023_18_34***.
  
Description of the output files  
  - ***Cleaned.ProteinSeq.faa*** contains proteins that were kept by the filter (proteins without conflicting taxon data)  
  - ***Contamination.ProteinSeq.faa*** contains proteins that were tagged as contamination and were removed from the input fata  
  - ***Ghost.ProteinSeq.faa*** contains proteins that are present in the input fasta file but are not mentioned in the gff / gtf annotation  
  - ***Contscout_{timestamp}.log is a log file with running parameters and messages from ContScout
  - ***various ".RDS" files are generated with saved intermediate data. All of them are in R data file format, and can be opened with readRDS() in R.
  
 Fasta headers in file in ***Contamination.ProteinSeq.faa*** contain information regarding the removed proteins in the following format:   
 \>{ID} ProtTag:{protein_taxon_call}\|ContigTag:{contig_level_taxon_call}\|CtgNumProt:{number_of_proteins_on_removed_contig}  
  Example:  
  \>XP_023876615.1 ProtTag:fungi|ContigTag:fungi|CtgNumProt:67
  
Explanation of ContScout parameters:
  - **-h** displays help message
  - **-u** (user directory) path to the folder, where the local reference database is stored
  - **-c** number of CPU-s to use (affects mainly the alignment step)
  - **-d** name of the database to be used
  - **-i** (input directory) path to the directory with the query data (contains subfolders FASTA_prot and GFF_annot)
  - **-q** the expected NCBI taxon ID of the query genome. Corresponds to the sequenced species that we screen for contamination.
  - **-f** when discovering inconsistencies between GFF annotation and fasta proteins file, this flag forces analysis to continue 
  - **-r** skip the database search and reuse ABC file from previous run if possible
  - **-n** perform the analysis without using any GFF/GTF annotation file
  - **-s** MMSeqs sensitivity parameter [default: 2]
  - **-x** which group to filter out. Accepted values: (all, viruses, bacteria, archaea, fungi, viridiplantae, metazoa, other_euk) [default:all]
  - **-p** minimum percentage of sequence identity required. This filter preceedes dynamic trimming. [default: 20]
  - **-t** location of the temporary folder. 
  - **-a** algorithm to be used for database lookup (mmseqs or diamond)
  
  
  
  

  
  
  


