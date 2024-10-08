# suboptimally hacked together! Apologies for the terrible code below.

# Steps:
# install data.table, fstcore and fst from source with Open MP flags
# https://github.com/Rdatatable/data.table/wiki/Installation
# add to ~.R/Makevars:
# LDFLAGS += -L/opt/homebrew/opt/libomp/lib -lomp
# CPPFLAGS += -I/opt/homebrew/opt/libomp/include -Xclang -fopenmp
# then do install.packages("path/to/source.tar", type="source", repos=NULL)
#
# The Data:
# https://www.ncbi.nlm.nih.gov/projects/SNP/docs/dbSNP_VCF_Submission.pdf
# download:
#     https://ftp.ncbi.nlm.nih.gov/snp/latest_release/VCF/GCF_000001405.25.gz (hg37) or GCF_000001405.40 (hg38).
# extract just the columns we want: (on the HPC load modules bcftools and samtools)
#     bcftools query -f '%ID %CHROM %POS %REF %ALT\n' GCF_000001405.25.gz | gzip -c > snp156_extracted.vcf.gz (add FREQ=%INFO/FREQ if you want frequency info column)
# rename to: snp156_extracted.vcf.gz.Z so that it works with zcat.... (?)
# split into smaller files of 25M rows each for easier processing
#     gunzip -c snp156_extracted.vcf.gz | split -l 25000000 - split_file_
# then run this r script to create binary fst files for each chromosome.

# list the split files created above (change the directory path below)
snp_files <- list.files("/Users/xx20081/Documents/local_data/genome_reference/dbsnp_raw", pattern = "split_file_*", full.names=TRUE)[38:47]

# cycle the file and extract the data to create the .fst files.
chrom_data <- data.table::data.table()
for(file in snp_files) {
  cat("Reading file:", basename(file), "\n")
  data <- data.table::fread(file, nThread=12)
  data.table::setnames(data, paste0("V",1:5), c("RSID","CHR","BP","REF","ALT"))

  # get the valid chromosomes
  unique_chroms <- unique(data[["CHR"]])
  valid_chr_patterns <- paste0(paste0("NC_", stringr::str_pad(1:24, 6, pad="0")), "\\.[0-9]+")
  valid_chr <- c()
  for (chrom in unique_chroms) {
    if(any(sapply(valid_chr_patterns, function(regex) grepl(regex, chrom)))) {
      valid_chr <- c(valid_chr, chrom)
    }
  }
  cat("Chroms:", paste0(valid_chr, collapse=", "), "\n")
  if(length(valid_chr)==0) {
    pout <- file.path(dirname(file), paste0("chr24.fst"))
    cat("...writing Chr24 data to:", pout, "\n")
    fst::write_fst(chrom_data, pout, compress=100)
    cat("Finished")
    break
  }

  # filter out the rest
  data <- data[CHR %in% valid_chr, ]

  # collect data
  if(length(valid_chr)==1) {

    cat("...gathering Chr", valid_chr, "data\n")
    chrom_data <- rbind(chrom_data, data)

  } else if (length(valid_chr)==2) {

    left_over <- data[CHR==valid_chr[2],]
    data <- data[CHR==valid_chr[1],]
    chrom_data <- rbind(chrom_data, data)
    # adjust the data andc write
    chrom_data[, CHR := sub("NC_[0]+([0-9]+)\\.[0-9]+", "\\1", CHR)]
    data.table::setkey(chrom_data, BP)
    print(str(chrom_data))
    chr_str <- sub("NC_[0]+([0-9]+)\\.[0-9]+", "\\1", valid_chr[1])
    pout <- file.path(dirname(file), paste0("chr", chr_str, ".fst"))
    cat("...writing Chr", valid_chr[1], "data to:", pout, "\n")
    fst::write_fst(chrom_data, pout, compress=100)
    chrom_data <- left_over

  } else if (length(valid_chr)==3) {

    left_over <- data[CHR==valid_chr[3],]
    complete_data <- data[CHR==valid_chr[2],]
    data <- data[CHR==valid_chr[1],]
    chrom_data <- rbind(chrom_data, data)
    # adjust the data and write data
    chrom_data[, CHR := sub("NC_[0]+([0-9]+)\\.[0-9]+", "\\1", CHR)]
    data.table::setkey(chrom_data, BP)
    print(str(chrom_data))
    chr_str <- sub("NC_[0]+([0-9]+)\\.[0-9]+", "\\1", valid_chr[1])
    pout <- file.path(dirname(file), paste0("chr", chr_str, ".fst"))
    cat("...writing Chr", valid_chr[1], "data to:", pout, "\n")
    fst::write_fst(chrom_data, pout, compress=100)

    # adjust the data and write middle
    complete_data[, CHR := sub("NC_[0]+([0-9]+)\\.[0-9]+", "\\1", CHR)]
    data.table::setkey(complete_data, BP)
    print(str(complete_data))
    chr_str <- sub("NC_[0]+([0-9]+)\\.[0-9]+", "\\1", valid_chr[2])
    pout <- file.path(dirname(file), paste0("chr", chr_str, ".fst"))
    cat("...writing Chr", valid_chr[2], "data to:", pout, "\n")
    fst::write_fst(complete_data, pout, compress=100)

    # send left over around again
    chrom_data <- left_over
  }
}

# Output-->
# at the end you should have a directory called 'dbsnp' with subfolder
# 'b37_dbsnp156' and/or 'b38_dbsnp156' depending on which build you downloaded above
# you should then provide the path to the `dbsnp` directory to the chrpos_to_rsid function
# for rsid annotation.
