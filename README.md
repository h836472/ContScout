# ContScout
**Background**  
ContScout is a pipeline developed to identify and remove contaminating sequences from draft genomes. As input, our tool requires two files: one with the predicted protein sequences in *fasta* format as well as the genome *annotation file* (gff, gff3 or gtf) linking protein IDs to contigs or scaffolds. (See user manual for details.)

**Working concept**  
Each query protein in the input file is first matched against a taxon-labelled reference database (for example: UniProtKB) using a speed-optimized search engine (MMSeqs, Diamond). Based on the taxon data from top-scoring database hits, each protein is assigned a taxon lineage. Protein-level taxon calls are then summarized over assembled genomic segments (scaffolds / contigs), followed by a consensus taxon lineage assignment. Contigs (scaffolds) that disagree with the query taxon are removed, including all the protein they encode. Filtering is performed at multiple taxon resolution (superkingdom, kingdom, class, order, family)

**Implementation**  
Contscout is implemented in R, pre-packaged as a Docker image, for convenient use.
Pre-compiled docker image can be downloaded by the following command:  
  
*docker pull h836472/contscout:latest*

**More information**  
Please consult Balint et al. 2022 "Purging genomes of contamination eliminates systematic bias from evolutionary analyses of ancestral genomes" manuscipt, with a pre-print copy available at https://biorxiv.org/cgi/content/short/2022.11.17.516887v1. 

**Note**
* The ContScout version that was used for the analyses described in the bioRxiv manuscript has been frozen and placed under the branch "bioRxiv_version". Journal review of the manuscript is on-going that has resulted in many changes in the tool, including a major improvement on the taxon labelling engine. Branch "main" holds the most up-to-date software version with the latest features. Please note that "main" branch is going trough a major update procedure in the following approximately two weeks. (8th July-20th July 2023) Before using this tool in production, please consult the authors to ensure you receive the latest tool and the most accurate user manual.


