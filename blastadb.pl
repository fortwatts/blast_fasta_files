#!usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Statistics::Frequency;

my $help = '';
my $directory = '';
my $similarity = '';
my $perc_identity = '';
my $qcov_hsp_perc = '';

GetOptions ("help|h|man|?" => \$help, "i=s" => \$directory) or die "Incorrect usage. Help on using this script is available using the option -h or --help \n";

my $help_text = "

PURPOSE:        This script relies on the file: nt_accessions.txt and blast 2.4+ with nt database.
                This script blasts the reads in the input directory fasta files to identify the species that match the read.

Input:          required:
                -i <directory> Directory containing .fasta files for processing.

                All .fasta files in the directory provided with the -i option will be processed.
                Data filenames must end with \".fasta\". For example, if Ion Torrent IonXpress barcode 17 was used with a sample to generate
                reads , a good filename would be: \"17.V1.fasta\"

Output:         files of the blast results and the blast results with the description added.

Usage:          \"perl newblastparser.pl -i <directory>\" where directory contains .fasta files for blasting.

";

if ( $help ) {print $help_text; exit;}
#remove any / the user may have put at the end of the directory given with -i
chomp ( $directory ); $directory =~ s/\/$//;
#check that the user provided directory doesn't contain any periods - this script has a bug that will cause errors if the directory name contains a period.
if ( $directory =~ /\./ ) {
        print "Error: this script cannot use directory names with periods in them, please rename your input directory.\n"; exit;
}

#check that the user provided a directory to work with.
if ( $directory eq '' ) {
        print "\nError: Input directory must be indicated with \"-i <directory>\".\nSee help with the -h option.\nExiting.\n"; exit;
}

#check that the directory provided exists and contains FASTA files using .fasta extension
my @filepath;
if ( -d $directory && -e $directory ) {
        @filepath = <$directory/*.fasta>;
        if ( scalar @filepath == 0 ) {
        print "Directory \"$directory\" does not contain any FASTA (.fasta) files. Exiting...\n"; exit;
        }
} else {
        print "Directory \"$directory\" does not exist or is not a directory. Exiting...\n"; exit;
}

# make a hash of the accession numbers and titles for annotating blast results later
print "\nStarting the hash, tighten your RAM.\n";
my $mapfile = 'nt_accessions.txt';
open ( MAP, "<", "$mapfile" ) or die "Can't open \$mapfile $mapfile : $!\n";
my %acc_id;
while (<MAP>) {
        chomp $_; my $i = $_; my @array = split(/ /,$i, 2); $acc_id{$array[0]} = $array[1];
#	print " array0 is: $array[0] and array1 is : @array[1]\n";
}
close MAP;

#Blast the files
my $time;
my $line;
my $read;
my $file;
my $header;
for $file ( @filepath ) {
    my $i=0;
    open ( IN, "<", $file ) or die "Can't open $file for reading";
    while ( <IN> ) {
	chomp $_;
	if ( $_ =~ m/^>/ ) {
        open ( BLAST, ">", "$file.blast");
        print BLAST "$_";
        close BLAST;
	$header = $_;
	}
	else {
            open ( BLAST, ">", "$file.blast");
            print BLAST "$_";
            close BLAST;
            `blastn -task="blastn" -db nt -query $file.blast -num_threads 8 -outfmt "6 qacc pident qcovs qseq saccver bitscore" -num_alignments 20 > $file.blastresults.txt`;
	    $i++;
            my $time = localtime;
            print $i, " reads have been processed from $file at $time\t\t\r";
            open ( RESULTS, "<", "$file.blastresults.txt" ) or die "Can't open the blast results text file $file.blastresults.txt : $!\n";
            open ( OUT, ">>", "$file.annotatedresults.txt");
	    my $linecount = 0;
	    my $bestbitscore = 0;
            while ( <RESULTS> ) {
                chomp $_;
                my @array = split(/\t/,$_);
                push ( @array, " ", $acc_id{$array[4]} );
		$array[0] = $header;
#		print "\nheader: $header pushed to array0: $array[0]";
                if ( ! defined $array[6] ) {
               	    $array[6] = "accession not found in nt_accessions.txt";
               	}
		$array[-1] =~ s/\n//;
		my $bitscore = $array[5];
		if ($linecount == 0) {
			$bestbitscore = $array[5];
			$linecount++;
		}
		elsif ( $bitscore >= $bestbitscore ) {
               		print OUT "@array\n";
			#print "\n$array[0]'s bitscore $array[5] matching $acc_id{$array[4]} added";
		}
		else {
			next;
		}
	      }
        `rm $file.blastresults.txt`;
        }
        close OUT;
        close RESULTS;
        $read = undef;
        `rm $file.blast`;
    }
print "All Reads in $file have been blasted\n";
}

print "\nExiting..\n";
exit;
