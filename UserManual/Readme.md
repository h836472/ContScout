**Summary**

ContScout is a software designed to identify and remove foreign sequences that appear in draft genomes as a consequence of contamination. The tool uses fast sequence lookup tools (MMSeqs or DIAMOND) to get taxonomical data for each predicted protein from a user-selected reference protein database (examples: uniprotKB, nr, refseq). As a major improvement over previous methods that rely on reference database and use a user-selected similarity threshold, ContScout applies a dynamic trimming on each hit list extracting the best-scoring hits that are most relevant when trying to classify proteins.
As an additional improvement, coding site spatial information from annotation (gff/gtf file) is used to calculate a consensus taxon call over assemby contigs / scaffolds. Then, all proteins from contigs / scaffolds with conflicting taxon information are marked from removal.  
  
__*Please note*__: with the current reference database taxon sampling, ContScout can only reliably differentiate between high level taxons, such as finding bacterial contamination in eukaryotes or identifying fungal contamination within plants. It is not designed for identifying contamination within a major eukaryote clade, such as identifying human contamination in an insect draft genome.  
For more information about the tool, please check out the ContScout manuscript under https://www.biorxiv.org/content/10.1101/2022.11.17.516887v1.  


