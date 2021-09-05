#!/usr/bin/env Rscript

# Load packages -----------------------------------------------------------

library(optparse)
library(dasper)

# Main --------------------------------------------------------------------

##### Set arguments #####

arguments <- parse_args(OptionParser(
  usage = "%prog [options] junction_paths samp_metadata", 
  description = paste0("Script to run dasper. Required inputs:\n", 
                       "<junction_paths>: ",
                       ".txt file with paths to the junctions in an SJ.out format.", 
                       "Must contain a single column with 1 path per line.\n", 
                       "<samp_metadata>: ", 
                       ".txt file containg the same number of rows as junction_paths.", 
                       "Contains the sample metadata."), 
  make_option(c("-o","--output"), default = "dasper", 
              help = paste0("The prefix for outputted junctions and outlier scores. ", 
                            "Will create 3 files", 
                            "<prefix>_junctions.rda, ", 
                            "<prefix>_junctions_to_plot.rda, ",
                            "<prefix>_outlier_scores.csv",
                            " [default %default]")),
  make_option(c("-o","--output"), default = "dasper", 
              help = paste0("The prefix for outputted junctions and outlier scores. ", 
                            "Will create 3 files; ", 
                            "<prefix>_junctions.rda, ", 
                            "<prefix>_junctions_to_plot.rda, ",
                            "<prefix>_outlier_scores.csv",
                            " [default %default]")),
  positional_arguments = 2))

opt=arguments$opt
counts_file=arguments$args[1]
groups_file=arguments$args[2]
