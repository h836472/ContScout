#!/usr/bin/Rscript
#setwd("/node7_data/balintb/databases")
#decect CPUs
cpu_info=system("lscpu",intern=T)
tpc=grep('Thread(s) per core:',cpu_info,fixed=T)
numT=cpu_info[tpc]
numT=as.numeric(gsub("^.+\\s","",numT))
numC=gsub("^.+\\s","",cpu_info[tpc-1])
numC=unlist(strsplit(numC,"-"))
numC_max=as.integer(length(seq(numC[1],numC[2]))/numT) #number of physical cores. IGNORE hyperthreading
library(parallel)
progname="update_DataBases.R"
cat("This is the database updater component of ContScout.\n")
cat("Loading R libraries.\n") #swicth C as CPU
suppressPackageStartupMessages(library("optparse"))
option_list = list(make_option(c("-b", "--basedir"), type="character", default=NULL, 
              help="Path to local database repository folder", metavar="basedir"),
make_option(c("-d", "--dbname"), type="character", default="uniref100",
                help='Database to download ("uniref" or "refseq_protein")', metavar="dbname"),
make_option(c("-c", "--cpu"), type="integer", default=0,
                help='Number of CPU-s to use. By default (-c 0) we use all CPUs available.', metavar="cpu"),
make_option(c("-y", "--yes"), action="store_true", default=FALSE,
                help='Automatically download database update.', metavar="YES"),

make_option(c("-l", "--localDB"), action="store_true", default=FALSE,
              help="Download databases from local sources. For testing only.", metavar="localDB"));

library(rjson)
#opt=list()
#opt[["basedir"]]="/node7_data/balintb/databases"
#opt[["localDB"]]=TRUE
#opt[["dbname"]]="refseq_prot"
#opt[["cpu"]]=10
#opt[["IO_cpu"]]=4

opt_parser = OptionParser(option_list=option_list,prog=progname);
opt = parse_args(opt_parser);

if(is.null(opt[["basedir"]]))
{
stop("Please set your local database directory with -b or --basedir option!")
}
#make this part more verbose later
opt[["dbname"]]=match.arg(opt[["dbname"]],c("uniref100","refseq_prot","ncbi_taxonomy"))

if(opt[["cpu"]]==0)
{
opt[["cpu"]]=numC_max
}else if(opt[["cpu"]]>numC_max){
opt[["cpu"]]=numC_max
}
opt[["IO_cpu"]]=min(opt[["cpu"]],8)
#####################################################################
#command "left_end" parts for database download
#either to use with "wget" from official web sources (normal operation)
#or to "cp" from local storage (testing / development only)
#####################################################################

dlc=list()
if(opt[["localDB"]])
{
dlc[["uniref100"]]="cp -f /node7_data/database_repository/uniprot/uniref100.fasta.gz "
dlc[["uniref100_info"]]="cp -f /node7_data/database_repository/uniprot/uniref100.release_note "
dlc[["ncbi_taxonomy"]]="cp -f /node7_data/database_repository/taxonomy/new_taxdump.tar.gz "
dlc[["ncbi_taxonomy_md5"]]="cp -f /node7_data/database_repository/taxonomy/new_taxdump.tar.gz.md5 "
dlc[["refseq_prot"]]="cp -f /node7_data/database_repository/refseq_protein/refseq_protein-prot-metadata.json "
}else
{
dlc[["uniref100"]]="wget --no-check-certificate https://ftp.expasy.org/databases/uniprot/current_release/uniref/uniref100/uniref100.fasta.gz -O "
dlc[["uniref100_info"]]="wget --no-check-certificate https://ftp.expasy.org/databases/uniprot/current_release/uniref/uniref100/uniref100.release_note -O "
dlc[["ncbi_taxonomy"]]="wget https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.tar.gz -O "
dlc[["ncbi_taxonomy_md5"]]="wget https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.tar.gz.md5 -O "
dlc[["refseq_prot"]]="wget --no-check-certificate https://ftp.ncbi.nlm.nih.gov/blast/db/refseq_protein-prot-metadata.json -O "
}
########################################################################################
#check if the database directory exists, is writeable and has at least 500 GB free space
########################################################################################
if(!file.exists(opt[["basedir"]]))
{
cat(paste0("Database repository folder ",opt[["basedir"]]," does not exist!\n"))
stop("Database download failed!")
} 

dbd.write=file.access(opt[["basedir"]],2)
if(!dbd.write==0)
{
cat(paste0("Database directory ",opt[["basedir"]]," is not writeable!\n"))
stop("Database download failed!")
}else{


dbd.df=system(paste0("df -P ",opt[["basedir"]]," -B 1G ",opt[["basedir"]]),intern=T)[2]
dbd.dfv=unlist(strsplit(dbd.df," +"))
dbd.free=as.numeric(dbd.dfv[[4]])
if(!dbd.free>=1000)
{
cat(paste0("There seems to be less than 1 TB free space in folder ",opt[["basedir"]],"!\n"))
stop("Database download failed!")
}
}

#####################
setwd(opt[["basedir"]])
dirs=list()
dirs[["tmpdir"]]=paste0(opt[["basedir"]],"/tmp")
dirs[["refseq_protdir"]]=paste0(opt[["basedir"]],"/refseq_prot")
dirs[["uniref100dir"]]=paste0(opt[["basedir"]],"/uniref100")
dirs[["taxdir"]]=paste0(opt[["basedir"]],"/ncbi_taxonomy")
res=lapply(dirs,function(d) if(!file.exists(d)){dir.create(d)})

log_DB_add=function(x,db,string)
{
string=matrix(unlist(strsplit(string,"_#_")),nrow=1)
string=data.frame(string,stringsAsFactors=F)
colnames(string)=c("db.Name","info.File","info.MD5","db.CRC","db.Loc","db.Version","nProt","annotTaxDB","date","is.Latest")
if(file.exists(x))
{
dbi.t=read.table(x,sep="\t",as.is=T,quote='"',header=T) #database, #folder, #fasta,#numprot #MD5, #jacksum
dbi.t[dbi.t[,"db.Name"]==db,"is.Latest"]="no"
dbi.new=rbind(dbi.t,string)
}else
{dbi.new=string
}
write.table(dbi.new,x,quote=T,row.names=F,col.names=T,sep="\t")
}

chk_update=function(what)
{
timestamp=paste0("tmp/update_checker_",format(Sys.time(),"%Y%m%d%H%M"))
if(!file.exists(timestamp)){dir.create(timestamp)}
dbi.f=paste0(opt[["basedir"]],"/db_inventory.txt")
if(!file.exists(dbi.f))
 {
 return(TRUE)
 }else
 {
 dbi.t=read.table(dbi.f,sep="\t",as.is=T,header=T,quote='"') 
 dbi.t=dbi.t[dbi.t[,"is.Latest"]=="yes",]
 rownames(dbi.t)=dbi.t[,"db.Name"]
 }
 #checking for uniref100
  if(what=="ncbi_taxonomy")
  {
  dl.cmd=paste0(dlc[["ncbi_taxonomy_md5"]],timestamp,"/new_taxdump.tar.gz.md5")
  system(dl.cmd)
  md5.latest=substr(readLines(paste0(timestamp,"/new_taxdump.tar.gz.md5")),1,32)
  md5.installed= dbi.t[what,"info.MD5"]
  if(is.null(md5.installed) || md5.installed!=md5.latest)
   {
   #there is update available
   return(TRUE)}else{
   #check that the previously downloaded database is still there
   if(file.exists(paste0("./",dbi.t["ncbi_taxonomy","db.Loc"],"_rankedlineage.dmp"))){
    return(FALSE) # we used to have the latest file but it is missing
    }else{return(TRUE)}
    }
  }
 if(what=="uniref100")
  {
  dl.cmd=paste0(dlc[["uniref100_info"]],timestamp,"/uniref100.release_note")
  system(dl.cmd)
  UR100.info=readLines(paste0(timestamp,"/uniref100.release_note"))
  UR100.rel=grep("Release: ",UR100.info,value=T)
  UR100.rel=gsub(", .+$","",gsub("^.+Release: ","",UR100.rel))
  UR100.nseqE=grep("Number of clusters: ",UR100.info,value=T)
  UR100.nseqE=gsub(",","",gsub("^.+Number of clusters: ","",UR100.nseqE))
  if(is.null(dbi.t["uniref100","Nprot"]) || UR100.nseqE!=dbi.t["uniref100","Nprot"])
   {
   #there is update available
   return(TRUE)}else{
   #check that the previously downloaded database is still there
   if(file.exists(dbi.t["uniref100","db.Loc"])){
    return(FALSE) # we used to have the latest file but it is missing
    }else{return(TRUE)}
    }
  }
  if(what=="refseq_prot")
  {
  dl.cmd=paste0(dlc[["refseq_prot"]],timestamp,"/refseq_protein-prot-metadata.json")
  system(dl.cmd)
  latest.md5=system(paste0("md5sum ",timestamp,"/refseq_protein-prot-metadata.json"),intern=T)
  existing.md5=dbi.t["refseq_protein","Info.MD5"]
  return(is.null(existing.md5) || latest.md5!=existing.md5) #if refseq_prot was not downloaded -> NULL, or if there is update available, value is TRUE
  }
}

downloader=list()
downloader[["ncbi_taxonomy"]]=function()
{
if(chk_update(what="ncbi_taxonomy"))
{
cat("Fetching NCBI taxonomy database.\n")
timestamp=paste0("ncbi_taxonomy",format(Sys.time(),"%Y%m%d%H%M"))
dir.create(paste0("tmp/",timestamp))
db.download.cmd=paste0(dlc[["ncbi_taxonomy"]],"tmp/",timestamp,"/new_taxdump.tar.gz")
md5.download.cmd=paste0(dlc[["ncbi_taxonomy_md5"]],"tmp/",timestamp,"/new_taxdump.tar.gz.md5")
system(db.download.cmd)
system(md5.download.cmd)
taxdump.md5=substr(system(paste0("md5sum tmp/",timestamp,"/new_taxdump.tar.gz"),intern=T),1,32)
taxdump.refmd5=substr(readLines(paste0("tmp/",timestamp,"/new_taxdump.tar.gz.md5")),1,32)
if(taxdump.refmd5!=taxdump.md5)
{
cat(paste0("NCBI taxonomy database failed to download!\n"))
stop("Download from NCBI failed!")
}else
{
system(paste0("tar -xvf tmp/",timestamp,"/new_taxdump.tar.gz -C tmp/",timestamp))
taxdump.crc32=gsub("\\t.+$","",system(paste0("jacksum -a crc32 -E hex tmp/",timestamp,"/rankedlineage.dmp"),intern=T))
dir.create(paste0("ncbi_taxonomy/",taxdump.crc32))
file.rename(paste0("tmp/",timestamp,"/rankedlineage.dmp"),paste0("ncbi_taxonomy/",taxdump.crc32,"/",taxdump.crc32,"_rankedlineage.dmp"))
unlink(paste0("tmp/",timestamp),recursive=T)
}
logtext=paste("ncbi_taxonomy",paste0("ncbi_taxonomy/",taxdump.crc32,"/",taxdump.crc32,"_rankedlineage.dmp"),taxdump.md5,taxdump.crc32,paste0("ncbi_taxonomy/",taxdump.crc32,"/",taxdump.crc32),taxdump.crc32,"NA",taxdump.crc32,Sys.time(),"yes",sep="_#_")
log_DB_add(paste0(opt[["basedir"]],"/db_inventory.txt"),"ncbi_taxonomy",logtext)
return(paste0("ncbi_taxonomy/",taxdump.crc32,"/",taxdump.crc32,"_rankedlineage.dmp"))
}else{
dbi.t=read.table(paste0(opt[["basedir"]],"/db_inventory.txt"),as.is=T,header=T)
dbi.t=dbi.t[dbi.t[,"is.Latest"]=="yes",]
rownames(dbi.t)=dbi.t[,"db.Name"]
dbi.t=dbi.t["ncbi_taxonomy",]
return(dbi.t[,"info.File"])
}
}


downloader[["uniref100"]]=function()
{
taxDB.file=downloader[["ncbi_taxonomy"]]()
taxdump.crc32=gsub("\\t.+$","",system(paste0("jacksum -a crc32 -E hex ",taxDB.file),intern=T))
#downloading the latest NCBI tax database
cat("Fetching Uniref100 database.\n")
timestamp=paste0("uniref100_",format(Sys.time(),"%Y%m%d%H%M"))
dir.create(paste0("tmp/",timestamp))

db.download.cmd=paste0(dlc[["uniref100"]],"tmp/",timestamp,"/uniref100.fasta.gz")
info.download.cmd=paste0(dlc[["uniref100_info"]],"tmp/",timestamp,"/uniref100.release_note")
system(db.download.cmd)
system(info.download.cmd)
system(paste0("gunzip tmp/",timestamp,"/uniref100.fasta.gz"))
UR100.info=readLines(paste0("tmp/",timestamp,"/uniref100.release_note"))
UR100.rel=grep("Release: ",UR100.info,value=T)
UR100.rel=gsub(", .+$","",gsub("^.+Release: ","",UR100.rel))
UR100.nseqE=grep("Number of clusters: ",UR100.info,value=T)
UR100.nseqE=gsub(",","",gsub("^.+Number of clusters: ","",UR100.nseqE))
UR100.nseqO=system(paste0('grep -c ">" tmp/',timestamp,"/uniref100.fasta"),intern=T)
if(UR100.nseqE!=UR100.nseqO)
{
stop("Number of proteins differ between info file and the uniref100 database.")
}
tax=readLines(taxDB.file)
tax=gsub("\\t\\|$","",tax)
tax.last=gsub("^.+\\t","",tax)
tax.simple=tax.last[tax.last%in%c("Archaea","Bacteria","Viruses")]
names(tax.simple)=paste0("t",gsub("\\t.+$","",tax[tax.last%in%c("Archaea","Bacteria","Viruses")]))
tax.euk=tax[tax.last=="Eukaryota"]
tax.euk2=mclapply(tax.euk,function(x) unlist(strsplit(x,"\\t\\|\\t")),mc.cores=opt[["cpu"]])
tax.euk3=sapply(tax.euk2,function(x) x[9])
tax.euk3[tax.euk3==""]="Other_eukaryote"
names(tax.euk3)=paste0("t",gsub("\\t.+$","",tax.euk))
taxDB=c(tax.simple,tax.euk3)
taxDB=taxDB[order(as.numeric(gsub("^t","",names(taxDB))))]
uni_con=file(paste0("tmp/",timestamp,"/uniref100.fasta"))
open(uni_con,open="r")
while(TRUE)
{
start=Sys.time()
chunk=readLines(uni_con,n=50000000) 
if(length(chunk)==0)
{
break
}else
{
fchar=substr(chunk,1,1)
headers=fchar==">"
nprot=sum(headers)
chunk.taxid=gsub("^.+TaxID=","t",chunk[headers])
chunk.taxid[chunk.taxid=="tN/A"]="t32644"
chunk.taxid=gsub(" .+","",chunk.taxid)
chunk.id=gsub(" .+$","",chunk[headers])
chunk.comment=gsub("^\\S+ ","",chunk[headers])
chunk.taxtext=taxDB[chunk.taxid]
newheaders=paste0(chunk.id,":",chunk.taxid,":",chunk.taxtext," ",chunk.comment)
chunk[headers]=newheaders
write.table(chunk,paste0("tmp/",timestamp,"/uniref100_tax.tmp"),append=T,quote=F,row.names=F,col.names=F)
stop=Sys.time()
cat (paste0("Processed ",nprot," proteins.\n"))
print(stop-start)
}
}
close(uni_con)
uni.crc=system(paste0("jacksum -a crc32 -E hex tmp/",timestamp,"/uniref100_tax.tmp"),intern=T)
uni.crc=gsub("\\t.+$","",uni.crc)
UR100.info=readLines(paste0("tmp/",timestamp,"/uniref100.release_note"))
UR100.rel=grep("Release: ",UR100.info,value=T)
UR100.rel=gsub(", .+$","",gsub("^.+Release: ","",UR100.rel))
dir.create(paste0("uniref100/",uni.crc))
outfile=paste0("uniref100/",uni.crc,"/",uni.crc,"_uniref100tax_v",UR100.rel,".fasta")
file.rename(paste0("tmp/",timestamp,"/uniref100_tax.tmp"),outfile)
outinfo=paste0("uniref100/",uni.crc,"/uniref100.release_note")
file.rename(paste0("tmp/",timestamp,"/uniref100.release_note"),outinfo)

mmseqs.cmd=paste0("mmseqs createdb ",outfile," ",gsub("\\.fasta$",".db",outfile))
system(mmseqs.cmd)
time.now=Sys.time()
system(paste0("pigz ",outfile))
uniinfo.md5=system(paste0("md5sum ",outinfo),intern=T)
uniinfo.md5=substr(uniinfo.md5,1,32)


logtext=paste("uniref100",outinfo,uniinfo.md5,uni.crc,paste0("uniref100/",uni.crc,"/",uni.crc),UR100.rel,UR100.nseqO,taxdump.crc32,Sys.time(),"yes",sep="_#_")

#logtext="uniref100_#_06ece9151bb9a50cfd61b079b4c8c057_#_c92e45ff_#_uniref100/c92e45ff/c92e45ff_uniref100tax_v2022_01.fasta_#_2022_01_#_297827854_#_1455156e_#_2022-05-10 12:48:08 CEST_#_yes"
log_DB_add(paste0(opt[["basedir"]],"/db_inventory.txt"),"uniref100",logtext)
}

downloader[["refseq_prot"]]=function()
{
taxDB.file=downloader[["ncbi_taxonomy"]]()
taxdump.crc32=gsub("\\t.+$","",system(paste0("jacksum -a crc32 -E hex ",taxDB.file),intern=T))
cat("Fetching NCBI Refseq protein database.\n")
timestamp=paste0("refseq_prot",format(Sys.time(),"%Y%m%d%H%M"))
dir.create(paste0("tmp/",timestamp))
info.download.cmd=paste0(dlc[["refseq_prot"]]," tmp/",timestamp,"/refseq_protein-prot-metadata.json")
system(info.download.cmd)
info.md5=system(paste0("md5sum tmp/",timestamp,"/refseq_protein-prot-metadata.json"),intern=T) 
info.data=fromJSON(file=paste0("tmp/",timestamp,"/refseq_protein-prot-metadata.json"))
chunks=matrix(ncol=5,nrow=length(info.data$files))
chunks[,1]=gsub("/refseq_protein-prot-metadata.json.+$","/",dlc[["refseq_prot"]])
chunks[,2]=gsub("^.+/","",info.data$files)
chunks[,3]=gsub("^.+/refseq_protein-prot-metadata.json","",dlc[["refseq_prot"]])
chunks[,4]=paste0("tmp/",timestamp,"/")
chunks[,5]=gsub("^.+/","",info.data$files)
chunks=apply(chunks,1,function(x) paste(x,collapse=""))
#downloading blast database chunks
lapply(chunks,function(x) system(x))
chunks.md5=gsub("\\.gz","\\.gz.md5",chunks)
lapply(chunks.md5,function(x) system(x))
gzf=list.files(pattern="gz$",paste0("tmp/",timestamp),full.name=T)
mdf=list.files(pattern="gz.md5",paste0("tmp/",timestamp),full.name=T)
mdd=lapply(mdf,function(x) readLines(x))
names(mdd)=gsub("\\.md5$","",gsub("^.+/","",mdf))
md5sums.exp=sapply(mdd,function(x) substr(x,1,32))
#check chunk md5sums here
md5sums.obs=mclapply(gzf,function(x) system(paste0("md5sum ",x),intern=T),mc.cores=opt[["IO_cpu"]])
names(md5sums.obs)=gsub("^.+/","",gzf)
md5sums.obs=sapply(md5sums.obs,function(x) substr(x,1,32))
if(!(length(md5sums.obs)==length(md5sums.exp) && all(names(md5sums.exp)==names(md5sums.obs))&& all(md5sums.exp==md5sums.obs)))
{
stop("Checksum mismatch, database download error!")
}
gzf=gzf[length(gzf):1]
lapply(gzf,function(x) system(paste0("tar -xvf ",x," -C tmp/",timestamp)))
setwd(paste0("tmp/",timestamp))
system(paste0('blastdbcmd -dbtype prot -db refseq_protein -entry all -outfmt ">%a\t%T\t%t\t%s" >',timestamp,"_dump.fasta")) #lookout! \t is recognized while \n is NOT.
num_prot_out=system(paste0('grep -c ">" ',timestamp,"_dump.fasta"),intern=T)
setwd(opt[["basedir"]])
tax=readLines(taxDB.file)
tax=gsub("\\t\\|$","",tax)
tax.last=gsub("^.+\\t","",tax)
tax.simple=tax.last[tax.last%in%c("Archaea","Bacteria","Viruses")]
names(tax.simple)=paste0("t",gsub("\\t.+$","",tax[tax.last%in%c("Archaea","Bacteria","Viruses")]))
tax.euk=tax[tax.last=="Eukaryota"]
tax.euk2=mclapply(tax.euk,function(x) unlist(strsplit(x,"\\t\\|\\t")),mc.cores=opt[["cpu"]])
tax.euk3=sapply(tax.euk2,function(x) x[9])
tax.euk3[tax.euk3==""]="Other_eukaryote"
names(tax.euk3)=paste0("t",gsub("\\t.+$","",tax.euk))
taxDB=c(tax.simple,tax.euk3)
taxDB=taxDB[order(as.numeric(gsub("^t","",names(taxDB))))]
refseq_con=file(paste0("tmp/",timestamp,"/",timestamp,"_dump.fasta"))
open(refseq_con,open="r")
while(TRUE)
{
start=Sys.time()
chunk=scan(refseq_con,n=2000000,what="char",sep="\t",quote="") 
if(length(chunk)==0)
{
break
}else
{
chunk=matrix(chunk,byrow=T,ncol=4)
nprot=nrow(chunk)
chunk[,2]=paste0("t",chunk[,2])
chunk=cbind(chunk,taxDB[chunk[,2]])
new.header=paste0(chunk[,1],":",chunk[,2],":",chunk[,5]," ",chunk[,3])
new.fasta=c(rbind(new.header,chunk[,4]))
write.table(new.fasta,paste0("tmp/",timestamp,"/",timestamp,"_tax.fasta"),append=T,quote=F,row.names=F,col.names=F)
stop=Sys.time()
cat (paste0("Processed ",nprot," proteins.\n"))
print(stop-start)
}
}
close(refseq_con)
refseq.crc=system(paste0("jacksum -a crc32 -E hex tmp/",timestamp,"/",timestamp,"_tax.fasta"),intern=T)
refseq.crc=gsub("\\t.+$","",refseq.crc)
dir.create(paste0("refseq_prot/",refseq.crc))
outfile=paste0("refseq_prot/",refseq.crc,"/",refseq.crc,"_refseq_prot_tax.fasta")
file.rename(paste0("tmp/",timestamp,"/",timestamp,"_tax.fasta"),outfile)
outinfo=paste0("refseq_prot/",refseq.crc,"/refseq_protein-prot-metadata.json")
file.rename(paste0("tmp/",timestamp,"/refseq_protein-prot-metadata.json"),outinfo)


mmseqs.cmd=paste0("mmseqs createdb ",outfile," ",gsub("\\.fasta$",".db",outfile))
system(mmseqs.cmd)
logtext=paste("refseq_prot",info.md5,refseq.crc,paste0("refseq_prot/",refseq.crc,"/",refseq.crc,"refseq_prot_tax.fasta"),refseq.crc,num_prot_out,taxdump.crc32,Sys.time(),"yes",sep="_#_")
#logtext="uniref100_#_06ece9151bb9a50cfd61b079b4c8c057_#_c92e45ff_#_uniref100/c92e45ff/c92e45ff_uniref100tax_v2022_01.fasta_#_2022_01_#_297827854_#_1455156e_#_2022-05-10 12:48:08 CEST_#_yes"
log_DB_add(paste0(opt[["basedir"]],"/db_inventory.txt"),"uniref100",logtext)
}

update_present=chk_update(what=opt[["dbname"]])
if(update_present)
{
cat(paste0('Update is available for \"',opt[["dbname"]],'\"'," database.\n"))
user.input <- function(prompt) {
  if (interactive()) {
    return(readline(prompt))
  } else {
    cat(prompt)
    return(readLines("stdin", n=1))
  }
}

if(!opt[["yes"]])
{
ans=user.input("Do you want to proceed with update? (yes/no)\n")
 if(ans=="yes")
 {
  downloader[[opt[["dbname"]]]]()
 }else
 {
 cat(paste0('Update of \"',opt[["dbname"]],'\"'," database was cancelled by user.\n"))
 }
}else{
 downloader[[opt[["dbname"]]]]()
}
}else{
cat(paste0("Database ",'\"',opt[["dbname"]],'\"'," is up to date.\n"))
}