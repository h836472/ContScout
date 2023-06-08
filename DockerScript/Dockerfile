#docker build ./ --tag h836472/contscout:latest
FROM ubuntu:latest
WORKDIR /data
RUN \
    apt-get update        && \
    apt-get install --yes    \
        build-essential      \
        gfortran             \
        python3-dev          \
        wget              && \
    apt-get clean all
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata &&\
apt-get install --yes libcurl4-openssl-dev libxml2-dev libssl-dev libmagick++-dev libcairo2-dev curl \
liblzma-dev libblas-dev aptitude libreadline-dev default-jdk cmake ncbi-blast+ locales libharfbuzz-dev libfribidi-dev
RUN ncpu=$(grep ^cpu\\scores /proc/cpuinfo | uniq |  awk '{print $4}') &&\
curl -O https://cran.rstudio.com/src/base/R-4/R-4.1.2.tar.gz &&\
tar -xzvf R-4.1.2.tar.gz &&\
cd R-4.1.2 &&\
    ./configure \
    --prefix=/opt/R/4.1.2 \
    --enable-memory-profiling \
    --enable-R-shlib \
    --with-blas \
    --with-lapack=\
    --with-x=no &&\
alias make="make -j $ncpu"    &&\
make &&\
make install &&\
cd .. &&\
rm -r R-4.1.2 &&\
rm R-4.1.2.tar.gz &&\
ln -s /opt/R/4.1.2/bin/R /usr/bin/R &&\
ln -s /opt/R/4.1.2/bin/Rscript /usr/bin/Rscript &&\
mkdir ~/.R &&\
echo 'MAKEFLAGS = -j4' >~/.R/Makevars&&\
echo 'options(Ncpus = XX)' >>~/.R/Makevars
RUN \
    R -e "if(!require('optparse',quietly=TRUE)) {install.packages('optparse',dependencies=TRUE,repos='http://cran.rstudio.com/')}" && \
    R -e "if(!require('bitops',quietly=TRUE)) {install.packages('bitops',dependencies=TRUE,repos='http://cran.rstudio.com/')}" && \
    R -e 'if (!require("BiocManager", quietly = TRUE)) {install.packages("BiocManager",dependencies=TRUE,repos="http://cran.rstudio.com/")}' &&\
    R -e 'if(!require('Biostrings',quietly=TRUE)) {BiocManager::install("Biostrings")}' &&\	
    R -e 'if(!require('rtracklayer',quietly=TRUE)) {BiocManager::install("rtracklayer")}' &&\	
    R -e 'if(!require('rJava',quietly=TRUE)) {install.packages("rJava")}' &&\
    R -e 'if(!require('xlsx',quietly=TRUE)) {install.packages("xlsx")}' &&\
    R -e 'if(!require('GenomicRanges',quietly=TRUE)) {BiocManager::install("GenomicRanges")}' 
#install latest DIAMOND
RUN ncpu=$(lscpu -b -p=Core,Socket | grep -v '^#' | sort -u | wc -l)
RUN curl -s https://api.github.com/repos/bbuchfink/diamond/releases/latest  | sed -Ene '/^ *"tag_name": *"v(.+)",$/s//\1/p' >/data/version.txt
RUN echo "export DVAR=`cat /data/version.txt`" >> /envfile
RUN . /envfile; echo $DVAR
RUN curl https://github.com/bbuchfink/diamond/archive/v`cat /data/version.txt`.tar.gz -L -o /data/diamond_latest_src.tar.gz
RUN tar -xvf /data/diamond_latest_src.tar.gz 
RUN mkdir /data/diamond-`cat /data/version.txt`/build_diamond && \
cd /data/diamond-`cat /data/version.txt`/build_diamond &&\
cmake .. &&\
make -j $ncpu &&\
make install -j $ncpu 
RUN rm diamond_latest_src.tar.gz

#install latest MMSEQS, including all CPU optimizations (avx2 > sse4.1 > sse2)
RUN echo "Installing latest MMSeqs."
#AVX2
RUN mkdir /opt/mmseqs_avx2
RUN wget https://mmseqs.com/latest/mmseqs-linux-avx2.tar.gz; tar xvfz mmseqs-linux-avx2.tar.gz -C /opt/mmseqs_avx2;
RUN ln -s /opt/mmseqs_avx2/mmseqs/bin/mmseqs /bin/mmseqs_avx2
#SSE4.1
RUN mkdir /opt/mmseqs_sse41
RUN wget https://mmseqs.com/latest/mmseqs-linux-sse41.tar.gz; tar xvfz mmseqs-linux-sse41.tar.gz -C /opt/mmseqs_sse41;
RUN ln -s /opt/mmseqs_sse41/mmseqs/bin/mmseqs /bin/mmseqs_sse41
#SSE2
RUN mkdir /opt/mmseqs_sse2
RUN wget https://mmseqs.com/latest/mmseqs-linux-sse2.tar.gz; tar xvfz mmseqs-linux-sse2.tar.gz -C /opt/mmseqs_sse2;
RUN ln -s /opt/mmseqs_sse/mmseqs/bin/mmseqs /bin/mmseqs_sse2
RUN rm mmseqs-linux*.gz
#ADD Jacksum
RUN wget https://github.com/jonelo/jacksum/releases/download/v3.5.0/jacksum-3.5.0.jar  && \
mv jacksum-3.5.0.jar /opt && \
echo '#!/bin/sh' >>/usr/bin/jacksum && \
echo 'java -jar "/opt/jacksum-3.5.0.jar" "$@"' >>/usr/bin/jacksum && \
chmod a+x /usr/bin/jacksum

#section to ensure that files are indeed pulled at build and NOT used from cache
ARG CACHEBUST=1
#at build, call an extra argument: --build-arg CACHEBUST=$(date +%s)

#ADD ContScout Downloader and main scripts
RUN wget https://github.com/h836472/ContScout/raw/main/R_scripts/ContScout
RUN mv ContScout /usr/bin/ContScout && chmod a+x /usr/bin/ContScout
RUN wget https://github.com/h836472/ContScout/raw/main/R_scripts/updateDB
RUN mv updateDB /usr/bin/updateDB&& chmod a+x /usr/bin/updateDB
