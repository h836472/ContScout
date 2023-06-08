# ContScout
**Background**  
ContScout is a pipeline developed for the identification and removal of contaminating sequences in draft genomes. As input, the tool requires two files: one with the predicted protein sequences in *fasta* format and a genome *annotation file* (gff, gff3 or gtf) linking protein IDs to contigs or scaffolds. (See user manual and tutorial more for details.)

**Working concept**  
Each query protein in the input file is first matched against a taxon-labelled reference database (for example: UniProtKB) using a speed-optimized search engine (MMSeqs, Diamond). Based on the taxon data from top-scoring database hits, each protein is assigned a taxon lineage. Protein-level taxon information is then summarized over assembled genomic segments (scaffolds / contigs), followed by a consensus taxon lineage call. At each taxon rank (superkingdom, kingdom, phylum, class, order, family), contigs that disagree with the query taxon are marked for removal together with all proteins they encode. 

**Implementation**  
Contscout is implemented in R, pre-packaged as a Docker image for convenient use. Docker image contains all the dependencies including the MMSeqs and Diamond software.
Pre-compiled docker image can be downloaded by the following command:  
*docker pull h836472/contscout:develop*

**More information**  
Please consult Balint et al. 2022 "Purging genomes of contamination eliminates systematic bias from evolutionary analyses of ancestral genomes" manuscipt, with a pre-print copy available at https://biorxiv.org/cgi/content/short/2022.11.17.516887v1. 

**Note**
* The ContScout version that was used for the analyses described in the bioRxiv manuscript has been frozen and placed under the branch "bioRxiv_version". Journal review of the manuscript is on-going that has resulted in many changes in the tool, including a major improvement on the taxon labelling engine. Branch "main" holds the most up-to-date software version with the latest features. Please note that "main" branch is going trough a major update procedure in the following approximately two weeks. (8th July-20th July 2023) Before using this tool in production, please consult the authors to ensure you receive the latest tool and the most accurate user manual.


