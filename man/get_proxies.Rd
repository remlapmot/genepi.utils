% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plink.R, R/class_gwas.R
\name{get_proxies}
\alias{get_proxies}
\title{Get proxies for variants from plink binary}
\usage{
get_proxies(
  x,
  stat = "r2-unphased",
  win_kb = 125,
  win_r2 = 0.8,
  win_ninter = Inf,
  proxy_eaf = NULL,
  plink2 = genepi.utils::which_plink2(),
  pfile = genepi.utils::which_1000G_reference(build = "GRCh37"),
  ...
)
}
\arguments{
\item{x}{a character vector of rsids or a GWAS object}

\item{stat}{character, the R stat to calculate, one of "r2-unphased", "r2-phased", "r-unphased", "r-phased"}

\item{win_kb}{numeric, the window to look in around the variants}

\item{win_r2}{numeric, the lower r2 limit to include in output, (for --r-phased and --r-unphased, this means |r|≥sqrt(0.2))}

\item{win_ninter}{numeric, controls the maximum number of other variants allowed between variant-pairs in the report. Inf = off.}

\item{proxy_eaf}{numeric, the minimal effect allele frequency for proxy variants. NULL = eaf filtering off.}

\item{plink2}{character / path, the plink2 executable}

\item{pfile}{character / path, the plink pfile set}

\item{...}{other arguments (see below)}

\item{snps}{a character vector (available if \code{x} is a \code{GWAS} object), a vector of rsids to ensure exist, or else try and find proxies for}

\item{then}{a string (available if \code{x} is a \code{GWAS} object), either \code{add} (adds proxies to current GWAS) or \code{subset}
(subsets GWAS to variants and potential proxies for variants in \code{x})}
}
\value{
a data.table of variants and their proxies (if \code{x} is a \code{character} vector) or a \code{GWAS} object if
\code{x} is a \code{GWAS} object.
}
\description{
Get proxies for variants from plink binary
}
