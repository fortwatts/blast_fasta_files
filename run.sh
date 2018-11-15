#!/bin/bash

module load blast/2/2.6.0

perl ~/work/blast_fasta_files/blastadb.pl -i ~/data/test -r ~/work/blast_fasta_files/nt_accessions.txt

