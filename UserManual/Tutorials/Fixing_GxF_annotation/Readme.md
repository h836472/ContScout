# GxF annotation fix hands on tutorial

**Background**

For ContScout to work properly, GxF annotation (GFF, GFF3 or GTF) file
should fulfill two criteria:

-  protein-coding features (CDS or gene) must have a "protein_id"
    attribute

-  protein_id tags from annotation file should match protein names in
    the fasta headers

**Example data (missing "protein_id" data)**

In this part of the tutorial, we are going to use **Augustus** to
perform automated annotation on an *E. coli* draft genome (assembly id:
GCF_000167835.1, taxonID: 562)

**Augustus command:**  
```
augustus --species=E_coli_K12 GCF_000167835.1_ASM16783v1_genomic.fna --gff3=on >GCF_000167835.1_ASM16783v1_Aug_Annot.gff3  
```

**Exporting protein sequences with gffread:**  
```
gffread -g GCF_000167835.1_ASM16783v1_genomic.fna -y GCF_000167835.1_ASM16783v1_Aug_Prot.faa GCF_000167835.1_ASM16783v1_Aug_Annot.gff3
```
Notice, when we attempt to use these files unmodified files with
ContScout, it will fail complaining about the "protein_id" fields
missing from the annotation.

```
singularity run -B /scratch:/scratch /Software/SingularityImages/contscout/contscout.sif ContScout -u /scratch/balintb/Databases/ -d uniprotKB -i /scratch/balintb/Augustus/E_coli/ -q 562
```

**Importing data to R using the ContScout docker image**

In the tutorial, we use the **R** environment straight from the
ContScout docker image trough together with the pre-installed
**rtracklayer** and **Biostrings** packages. To do so, please navigate
to the query directory that contains "annotation_data" and "protein_seq"
and start R.
```
singularity run -B \`pwd\`:/data docker://h836472/contscout:latest R
```

```
#ensure that annotation file and sequence file are both present  
list.files(recursive=T)

#[1] "annotation_data/GCF_000167835.1_ASM16783v1_Aug_Annot.gff3"
#[2] "protein_seq/GCF_000167835.1_ASM16783v1_Aug_Prot.faa"

#load required R libraries  
library("Biostrings")
library("rtracklayer")

#load data  
protSeq=readAAStringSet("protein_seq/GCF_000167835.1_ASM16783v1_Aug_Prot.faa")  
annot=readGFF("annotation_data/GCF_000167835.1_ASM16783v1_Aug_Annot.gff3")

#manually confirm that protein_id is missing from the annotation  
colnames(annot)
#[1] "seqid" "source" "type" "start" "end" "score" "strand" "phase"
#[9] "ID" "Parent"  
  
#check the feature types present in the annotation file. Ensure that
CDS is present.
any(annot[,"type"]=="CDS")
#TRUE

#add a new annotation column, filled with NA-s
annot[,"protein_id"]=NA

#for all CDS features, we copy the tags from "ID" to "protein_id"  
annot[annot[,"type"]=="CDS","protein_id"]=annot[annot[,"type"]=="CDS","ID"]  
  
#check if the protein_IDs from annotation match IDs of the protein
sequences  
length(setdiff(names(protSeq),annot[,"protein_id"]))/length(protSeq)*100
#[1] 100  

length(intersect(names(protSeq),annot[,"protein_id"]))/length(protSeq)*100  
#[1] 0

#unfortunately, IDs look completely different between protein seq and
annotation  
#if we continue like that, ContScout will give an error  
#Error! Protein IDs in the protein sequence file completely differ from
the IDs used in the GFF file.

#Looking at the IDs it appears that the GFF IDs contain an extra ".cds"
suffix. Let's remove it.
 
annot[,"protein_id"]=gsub("\\.cds$","",annot[,"protein_id"])
length(setdiff(names(protSeq),annot[,"protein_id"]))/length(protSeq)*100  
#[1] 0  
length(intersect(names(protSeq),annot[,"protein_id"]))/length(protSeq)*100
#[1] 100  
#protein seq and annotation data is completely matched by now
export(annot,"annotation_data/GCF_000167835.1_ASM16783v1_Aug_AnnotFixed.gff3",format="gff3")  
  
#Do not forget to remove the old GFF from the query folder before starting ContScout
unlink("annotation_data/GCF_000167835.1_ASM16783v1_Aug_Annot.gff3")
```
After these modifications, ContScout is good to go.
