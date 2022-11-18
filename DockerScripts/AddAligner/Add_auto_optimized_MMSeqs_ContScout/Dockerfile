FROM h836472/cs_baseimage:latest
WORKDIR /data
COPY downloadMM.sh /bin/downloadMM.sh
RUN downloadMM.sh
COPY ContScout /bin/ContScout
RUN chmod a+x /bin/ContScout
