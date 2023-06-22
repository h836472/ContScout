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
- **-h / --help** #displays help message
- **-u / --userdir** #user directory. This is the location to store the local database copy.  
- **-c / --cpu**  #number of CPU-s to use (affects mainly the alignment step)  
- **-t / --tempdir** #Directory to write temporary files while installing a database.  
- **-l / --list_databases** #Prints a summary on the console about nstalled databases found in the user directory.  
- **-d / --dbname** #database to be downloaded (nr, uniref,uniprotKB, or custom)  
- **-i / --info** #database descriptor file with links to public sequence databases. Currently points to https://docs.google.com/spreadsheets/d/1_FPaAnyHVUhHzV8gwic2X3RKaN9vSl9jcTN_50T7X24  

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


  
Explanation of ContScout parameters:
  - **-h / --help** #displays help message
  - **-u / --userdir** #path to the folder, where the local reference database is stored
  - **-U / --unknown** #shall the tool keep or drop contigs that can not be tagged (mixed signal, unknown proteins). Default: keep
  - **-c / --cpu** #number of CPU-s to use (affects mainly the alignment step)
  - **-w / --what** #main project name [default: name derived from NCBI taxonID]
  - **-d / --dbname** #name of the pre-formatted database to be used (within the user folder)
  - **-i / --inputdir** #path to input directory with the query data (contains subfolders *protein_seq* and *annotation_data*)
  - **-q / --querytax** #the expected NCBI taxon ID of the query genome. Corresponds to the sequenced species that try to remove contamination from.
  - **-f / --force** #when discovering inconsistencies between GFF annotation and fasta proteins file, this flag forces analysis to continue 
  - **-r / --reuse_abc** #skip the database search and reuse ABC file from previous run if possible
  - **-n / --no_annot** #perform the analysis without using any annotation file. Not recommended.
  - **-s / --sensM** #MMSeqs sensitivity parameter [default: 2]
  - **-S / --sensD** #Diamond sensitivity parameter [default: "fast"]
  - **-p / --pci** #minimum percentage of sequence identity required. [default: 20]
  - **-m / --memlimit** #limit Diamond / MMSeqs to use this amount of RAM. [example: 150G]
  - **-t/ --temp** #location of the temporary folder. 
  - **-a/ -aligner-** #algorithm to be used for database lookup (mmseqs or diamond)
  
    
  

  
  
  


