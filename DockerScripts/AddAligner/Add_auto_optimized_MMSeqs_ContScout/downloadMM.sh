#!/usr/bin/bash
AVX2=$(lscpu | grep avx2 | wc -l)
SSE41=$(lscpu | grep sse4_1 | wc -l)
if  (( $AVX2 == 1)) ; then
 echo "AVX2"
wget https://mmseqs.com/latest/mmseqs-linux-avx2.tar.gz; tar xvfz mmseqs-linux-avx2.tar.gz -C /opt; 
elif  (( $SSE41 == 1)) ; then
 echo "SSE v4.1"
wget https://mmseqs.com/latest/mmseqs-linux-sse41.tar.gz; tar xvfz mmseqs-linux-sse41.tar.gz -C /opt; 
else
  echo "SSE2"
wget https://mmseqs.com/latest/mmseqs-linux-sse2.tar.gz; tar xvfz mmseqs-linux-sse2.tar.gz -C /opt; 
fi
ln -s /opt/mmseqs/bin/mmseqs /bin/mmseqs
rm mmseqs-linux*.gz
