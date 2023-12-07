This tutorial will guide users trought ContScout using a small demo dataset derived from *Quercus suber*.

**Prerequisites**  
-Install ContScout   
-Download and pre-format the **demoDB** reference database (see custom database import in "1_Database_import" section.  
-Download demo query data (se below)

**Download demo query data**
>cd ~/CS_dir 
>mkdir query 
>mkdir query/Quersube_tax_58331 
>cd query/Quersube_tax_58331 
>wget -c https://github.com/h836472/ContScout/raw/main/UserManual/Tutorials/TutorialExampleData/DemoQuery_tax_58331.tar.gz 
>tar -xvf DemoQuery_tax_58331.tar.gz 
>rm DemoQuery_tax_58331.tar.gz 
>cd ~/CS_dir/query 

**Perform ContScout analysis**  
>singularity run ~/CS_dir/singularity_image/contscout_latest.sif ContScout -u ~/CS_dir/databases -d swissprot -i ~/CS_dir/query/Quersube_tax_58331 -q 58331
