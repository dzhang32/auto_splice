#!/usr/bin/env Rscript

# Load packages -----------------------------------------------------------

library(optparse)
library(dasper)
library(readr)

# Set arguments -----------------------------------------------------------

parser <- OptionParser(
  usage = "auto_dasper.R [options] junction_paths samp_metadata\n", 
  description = paste0("Inputs:\n", 
                       "<junction_paths>: ",
                       ".txt file with paths to the junctions in an SJ.out format. ", 
                       "Must contain a single column with 1 path per line.\n", 
                       "<samp_metadata>: ", 
                       ".txt file containg the same number of rows as junction_paths, ", 
                       "containing the sample metadata. ", 
                       "Must contain a column titled case_control, with contents ", 
                       "labelling cases as 'case', controls as 'control'.\n\n", 
                       "Outputs:\n", 
                       "<output>_junctions.rda\n", 
                       "<output>_junctions_to_plot.rda\n",
                       "<output>_outlier_scores.csv")
)

parser <- parser %>% 
  add_option(c("-o", "--output"),
             default = "dasper", 
             help = paste0("The prefix for outputted junctions and outlier scores. ", 
                           " [default %default]"))

parser <- parser %>% 
  add_option(c("-r", "--ref"),
             default = "/data/gtf/Homo_sapiens.GRCh38.104.gtf.gz", 
             help = paste0("Path to the gtf to be used to annotated junctions.",
                           " [default %default]"))

parser <- parser %>% 
  add_option(c("-c", "--covariates"),
             default = NULL, 
             help = paste0("Name of covariate cols in samp_metadata to regress out. ", 
                           "In the form var1,var2,var3, ... \n",
                           "character variables will be converted to factors, ",
                           "numeric/double variables will be used as is.",
                           " [default %default]"))

# Testing -----------------------------------------------------------------

parse_args(parser, args = c("--help"), 
           print_help_and_exit = TRUE)

args <- parse_args(parser, 
                   args = c(
                     paste0("--output=", tempdir(), "/", "dasper_test"),
                     paste0("--covariates=", "RIN"),
                     file.path(tempdir(), "junction_paths.txt"),
                     file.path(tempdir(), "samp_metadata.csv")
                   ), 
                   positional_arguments = 2)

args

# Main --------------------------------------------------------------------

##### junction_load #####

junction_paths <- readr::read_lines(args[["args"]][1])
samp_metadata <- readr::read_delim(args[["args"]][2], delim = ",")
case_control <- samp_metadata[["case_control"]] == "controls"

# keep only canonical chromosomes
junctions <- 
  dasper::junction_load(
    junction_paths = junction_paths, 
    metadata = samp_metadata, 
    chrs = c(1:22, "X", "Y", "MT"), 
    controls = case_control
  )

##### junction_filter #####

# first pass filter 
# count of 1 in 5% of samples
# width between 20b-1Mb
# TO DO - add regions to docker
junctions <- junction_filter(
  junctions,
  count_thresh = c("raw" = 1),
  n_samp = c("raw" = ncol(junctions) * 0.05) %>% round(0),
  width_range = c(20, 1000000),
  regions = NULL)

##### junction_annot #####

ref <- dasper:::.ref_load(args[["options"]][["ref"]])

junctions <- dasper::junction_annot(junctions, ref)

##### junction_filter #####

# second pass filter 
# removing ambig_gene and unannotated junctions
junctions <- dasper::junction_filter(
  junctions,
  count_thresh = NULL, 
  n_samp = NULL,
  types = c("ambig_gene", "unannotated")
)

##### junction_norm #####

junctions <- dasper::junction_norm(junctions)

##### regress out covariates #####

covars <- args[["options"]][["covariates"]] %>% 
  stringr::str_split(",") %>% 
  unlist()

samp_metadata <- SummarizedExperiment::colData(junctions)

if(!all(covars %in% colnames(samp_metadata))){
  
  stop(paste0("At least one of the covariates is not found in samp_metadata"))
  
}

# create tibble of covars
covars <- samp_metadata %>% 
  dplyr::as_tibble() %>% 
  dplyr::select(dplyr::one_of(covars)) %>% 
  dplyr::mutate_if(.predicate = is.character, 
                   .funs = as.factor) 

# create function to obtain residuals after regressing out covars
regress_covar <- function(counts, covar){
  
  lm_res <- lm(counts ~ ., data = covar)[["residuals"]]
  
  return(lm_res)
  
}

# get count matrix
count_matrix <- SummarizedExperiment::assays(junctions)[["norm"]]

# regress out the covariates of interest 
count_matrix_corrected <- apply(t(count_matrix), 
                                MARGIN = 2,
                                FUN = regress_covar, 
                                covar = covars)

# to match junctions
count_matrix_corrected <- t(count_matrix_corrected)
colnames(count_matrix_corrected) <- colnames(junctions)

stopifnot(identical(colnames(count_matrix_corrected), colnames(junctions)))

SummarizedExperiment::assays(junctions)[["norm_regress"]] <- count_matrix_corrected

# junction_score ----------------------------------------------------------

# save a version of junctions for downstream dasper::plot_sashimi()
# junction_score() removes the control data from the RSE
junctions_to_plot <- junctions
junctions <- junctions %>% dasper::junction_score()

# outlier_process ---------------------------------------------------------

outlier_score_no_cov <- dasper::outlier_process(junctions, feature_names = c("score"))

# Save data ---------------------------------------------------------------

save(junctions, 
     file = paste0(args[["options"]][["output"]], "_junctions.rda"))

save(junctions_to_plot, 
     file = paste0(args[["options"]][["output"]], "_junctions_to_plot.rda"))

save(outlier_score_no_cov, 
     file = paste0(args[["options"]][["output"]], "_outlier_score_no_cov.rda"))
