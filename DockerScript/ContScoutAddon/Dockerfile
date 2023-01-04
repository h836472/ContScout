FROM h836472/cs_baseimage:latest
RUN apt-get install locales
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
RUN unset R_HOME
WORKDIR /data
RUN wget https://mmseqs.com/latest/mmseqs-linux-avx2.tar.gz; tar xvfz mmseqs-linux-avx2.tar.gz -C /opt;
RUN ln -s /opt/mmseqs/bin/mmseqs /bin/mmseqs
RUN rm mmseqs-linux*.gz
COPY ContScout /bin/ContScout
RUN chmod a+x /bin/ContScout
