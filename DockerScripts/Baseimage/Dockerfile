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
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata
RUN apt-get install --yes libcurl4-openssl-dev libxml2-dev libssl-dev libmagick++-dev libcairo2-dev curl \
liblzma-dev libblas-dev aptitude libreadline-dev default-jdk
RUN mkdir install
RUN cd install
RUN curl -O https://cran.rstudio.com/src/base/R-4/R-4.1.2.tar.gz
RUN tar -xzvf R-4.1.2.tar.gz 
RUN cd R-4.1.2 &&\
    ./configure \
    --prefix=/opt/R/4.1.2 \
    --enable-memory-profiling \
    --enable-R-shlib \
    --with-blas \
    --with-lapack=\
    --with-x=no &&\
make -j 4 &&\
make -j 4 install
RUN cd /
RUN rm -r R-4.1.2
RUN rm R-4.1.2.tar.gz 
RUN ln -s /opt/R/4.1.2/bin/R /usr/bin/R
RUN ln -s /opt/R/4.1.2/bin/Rscript /usr/bin/Rscript
RUN \
    R -e "if(!require('optparse',quietly=TRUE)) {install.packages('optparse',dependencies=TRUE,repos='http://cran.rstudio.com/')}" && \
    R -e "if(!require('bitops',quietly=TRUE)) {install.packages('bitops',dependencies=TRUE,repos='http://cran.rstudio.com/')}" && \
    R -e "if(!require('huxtable',quietly=TRUE)) {install.packages('huxtable',dependencies=TRUE,repos='http://cran.rstudio.com/')}" && \
    R -e 'if (!require("BiocManager", quietly = TRUE)) {install.packages("BiocManager",dependencies=TRUE,repos="http://cran.rstudio.com/")}' &&\
    R -e 'if(!require('Biostrings',quietly=TRUE)) {BiocManager::install("Biostrings")}' &&\	
    R -e 'if(!require('rtracklayer',quietly=TRUE)) {BiocManager::install("rtracklayer")}' &&\	
    R -e 'if(!require('GenomicRanges',quietly=TRUE)) {BiocManager::install("GenomicRanges")}' 
