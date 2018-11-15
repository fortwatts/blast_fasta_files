#!/bin/bash

#PBS -W group_list=gwatts # or bhurwitz
#PBS -q standard # or priority
#PBS -l jobtype=cluster_only
#PBS -l select=1:ncpus=2:mem=4gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

module load blast/2/2.6.0

perl ~/work/blast_fasta_files/blastadb.pl -i ~/data/test -r ~/work/blast_fasta_files/nt_accessions.txt

