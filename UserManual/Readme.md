**Summary**

ContScout is a software designed to identify and remove foreign sequences that appear in draft genomes as a consequence of contamination. The tool uses fast sequence lookup tools (MMSeqs or DIAMOND) to get taxonomical data for each predicted protein from a user-selected reference protein database (examples: uniprotKB, nr, uniref). With the current version, ContScout performs taxon call for each query sequences at multiple taxon levels (superkingdom, kingdom, phylum, class, order and family). In addition to the taxon label, a vote weight (between 1.0 and 2.0) is added, depending on the number of top-scoring consecutive hits that back up the taxon call. Based on the user-provided annotation file (gff/gtf file), proteins are grouped according according to assembled contigs / scaffolds and individual taxon votes are summed to yield a consensus taxon call for each contig / scaffolds. At each taxon level, contigs with taxon label not matching the expected lineage of the query genome are marked for removal, together with all coded proteins.
  
__*Please note*__: Reference database taxon sampling has a big effect on ContScout ability to separate a contaminant from a closely related host. If both genomes have at least a few close representatives from the same family, ContScout is expected to accurately distinguish contamination from host proteins. However, for a sparsely sampled query, analysis at finer taxonomic resolution (family, order) might not be feasible. The program has excessive diagnostic capabilities to inform the users about potentially conflicting situations at which the results need to be handled with care. (see examples below) 

**System requirements**

ContScout is written in R language. Both the code and the external apps it depends on are designed to run in a Unix/Linux environment and was tested on several Linux distributions (Ubuntu, Debian, CentOS), although with the containerization (Docker, Singularity) running the tool should be possible on a machine with Windows / MacOS as well...  

External application as well as some ContScout components benefit from SMP multi-cpu machines and the system is written to automatically find the best vector instructions that the processor supports (avx2 >> sse4.1 >> sse2). Due to working with huge databases, ContScout requrires at least 128 GB of RAM and 500 GB of storage space but depending on the number of locally mirrored reference databases the storage footprint can easily reach several TeraBytes. There is a trade between allocated RAM and database search time where adding more RAM (256 GB, 512GB or 1 TB) significantly speeds up the database lookup step. Typical installation time for the tool from Dockerfile is less then an hour. Typical database setup for "test" (swissprot, tutorial) databases is a matter of minutes, while "real" databases take several hours to download and pre-format before analysis. Runtime for a typical eukaryote genome is between 1 and 2 hours on a 24-core server / workstation computer.

**Installation**

ContScout can be installed by
  
(1) **natively**, by downloading the two main scripts "updateDB" and "ContScout" after manually installing all pre-requisites. Please note that this is not recommended although authors can provide help with the local installation if needed. 
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

(2) as **locally built Docker image**, created from the docker file provided at GitHub (Recommended for advanced users / developers)  
> mkdir ~/CS_install
> cd ~/CS_install
> git clone https://github.com/h836472/ContScout.git
> cd ContScout/DockerScript/
> docker build ./ --tag contscout:latest> --build-arg CACHEBUST=$(data+%s)
Please allow 40-60 minutes of compilation time.

(3) ready-to-use (binary) **Singularity image**, obtained from DockerHub  
> mkdir ~/CS_install  
> cd ~/CS_install  
> singularity build contscout_latest.sif docker://h836472/contscout:latest  

(4)ready-to-use (binary) **Docker image**, obtained from DockerHub  
> mkdir ~/CS_install  
> cd ~/CS_install  
> docker pull h836472/contscout:latest  

**Set up your local reference databases**

The ContScout package contains an automated database updater tool called "updateDB" that fetches, labels and pre-formats public protein databases, such as uniref, nr or uniprotKB. Taxonomical labeling is based on the taxonomy database from NCBI.  
You can check the command line parameters of the tool from Docker / Singularity
> Docker: docker run h836472/contscout:latest updateDB -h
> Singularity: singularity exec <cs_sif_file> updateDB -h

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
 
**How to run ContScout**
- check if your computer meets the program's minimum requirements (150 GB RAM, 500 GB of storage. Recommended: >=512 GB RAM, >=4 TB storage)  
- install ContScout  
- install a reference database using updateDB  
- create an input folder for your query data, that shall contain two subfolders: "protein_seq" and "annotation_data" 
- place fasta protein file in "protein_seq" folder  
- place the (gtf or gff) annotation file annotation file in "annotation_data" folder  
- look up the taxon ID for your genome of interest in NCBI taxonomy database. 
- check if the default parameters fit your analysis (-U, -f, -s, -S, -a -m, -w)  
- run ContScout
- check the console message / log files for warnings / errors.
- carefully check $PROJECTNAME_RunDiag.xls. This file holds important metrices about the run performance. (see output file explanaiton below and tutorial)
  
Explanation of ContScout parameters:
  - **-h / --help** #displays help message
  - **-u / --userdir** #path to the folder, where the local reference database is stored
  - **-U / --unknown** #shall the tool keep or drop contigs that can not be tagged (mixed signal, unknown proteins). Default: keep
  - **-c / --cpu** #number of CPU-s to use (affects mainly the alignment step)
  - **-C / --consensus** #fraction of votes needed to call a consensus taxon tag on a contig. [Default: 0.5. Range: 0.5-0.9999]
  - **-w / --what** #main project name [default: name derived from NCBI taxonID]
  - **-d / --dbname** #name of the pre-formatted database to be used (within the user folder)
  - **-i / --inputdir** #path to input directory with the query data (contains subfolders *protein_seq* and *annotation_data*)
  - **-q / --querytax** #the expected NCBI taxon ID of the query genome, that we try to validate / decontaminate.
  - **-f / --force** #when discovering inconsistencies between GFF annotation and fasta proteins file, this flag forces analysis to continue 
  - **-r / --reuse_abc** #skip the database search and reuse ABC file from previous run if possible
  - **-n / --no_annot** #perform the analysis without using any annotation file. Not recommended.
  - **-s / --sensM** #MMSeqs sensitivity parameter [default: 2]
  - **-S / --sensD** #Diamond sensitivity parameter [default: "fast"]
  - **-p / --pci** #minimum percentage of sequence identity required. [default: 20]
  - **-m / --memlimit** #limit Diamond / MMSeqs to use this amount of RAM. [example: 150G]
  - **-t/ --temp** #location of the temporary folder. 
  - **-a/ -aligner-** #algorithm to be used for database lookup (mmseqs or diamond)

*Run example for the impatient* (assuming locally installed tool, placed in search path):

>cd #enter your home folder  
>mkdir test  
>mkdir test/query  
>mkdir test/query/protein_seq  
>mkdir test/query/annotation_data  
>mkdir test/database  
>updateDB -u ~/test/database -d swissprot  
>wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/146/045/GCF_000146045.2_R64/GCF_000146045.2_R64_protein.faa.gz -O test/query/protein_seq/GCF_000146045.2_R64_protein.faa.gz  
>wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/146/045/GCF_000146045.2_R64/GCF_000146045.2_R64_genomic.gff.gz -O test/query/annotation_data/GCF_000146045.2_R64_genomic.gff.gz  
>updateDB -u ~/test/database -d swissprot  
>ContScout -u ~/test/database -d swissprot -i ~/test/query/ -q 559292 -t /tmp 

**Explanation of the output folders**    
  
Outputs of ContScout are organized in an output folder (example: *Saccharomyces_cerevisiae_S288C_tax_559292_23Jun_2023_07_26*), distributed in several subfolders (*diag_data*, *R_saved_objects*, *filtred_outputs*) . Directory "diag data" contains a $ProjectName_RunDiag.xlsx that provides user with essential quality control data regarding the run.
The core assumption behind ContScout is that true contamination is organized into homogenous contigs / scaffolds while other foreign-looking proteins (including ones obtained via horizontal gene transfer) are sharing contigs with genuine host proteins. To this end, ContScout compares individually picked foreign-looking proteins ("IndivProtDrop") with proteins based on contig filtering (CtgProtDrop).   
  
**Important to note:**  
Depending on the reference database, the number of closely related sequences at a fine-grade taxon level could be low. In such case, the top hits of some genuine host proteins might apper from sister clades instead of the expected taxon. Currently, ContScout flags any taxon mismatch as potential contamination and tries to resolv these cases at the next level, where hits are summarized over contigs.

**Indicators of dubious analysis results at particular taxon levels:**
- value at medRLE (that is the median number of reads supporting individual protein taxon calls) dropping below 5
- mixed taxon tags, that are present both in the "kept" and "dropped" groups appear. 
- value in "IndivProtDrop" column sharply rises while "CtgProtDrop" value remains low. Jackard value remains close to 0, indicating conflicts between individually marked and contig-level marked proteins.
- in extreme cases, a large fraction of query proteins might appear tagged for removal either exclusively in CtgProtDrop or both in CtgProtDrop and CtgProtDrop columns.

**Indicators of the reliable analysis results:**  
- MedRLE values remaining high (>10) for each taxon level  
- few mixed taxon appearing between kept and dropped protein groups. If there is taxon mix, the vast majority of mixed-tag proteins remain in the *host* section.  
- similar values appear at IndivProtDrop and CtgProtDrop columns, with the Jaccard value being close to 1, indicating good agreement between the individual protein tags and contig-based calls  
- similar CtgProtDrop values appearing across multiple consecutive taxon levels  
  
Once ContScout finishes, host and contamination protein files created at each taxon level are written in the "filtered outputs", together with a taxon table summary. Folder R_saved_object holds various data tables and lists saved during the analysis in R data format. They can be opened within an R console with command readRDS. Important diagnostics data files include "rescall.RDS" and "ctgDB_with_taxCalls.RDS"   

These RDS files are saved for debugging purposes and the formats and contents are not discussed in detail in the user manual. Please contact the authors if you have any question regaring these RDS files.



