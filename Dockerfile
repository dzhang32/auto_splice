FROM bioconductor/bioconductor_docker:RELEASE_3_13

# need cmake for installing 
RUN apt-get update \
    && apt-get install -y --no-install-recommends cmake \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# install leafcutter and dependencies regtools and samtools into /tools
RUN mkdir /tools \
    && cd /tools \
    && git clone https://github.com/davidaknowles/leafcutter \
    && git clone git://github.com/samtools/samtools.git \
    && git clone https://github.com/griffithlab/regtools \
    && cd regtools/ \
    && mkdir build \
    && cd build/ \
    && cmake .. \
    && make \
    && chown -R rstudio:rstudio /tools \
    && chmod -R 755 /tools
    
# install R packages, dasper, rstan, and leafcutter
# needed to manually install DirichletMultinomial, Rcpp for leafcutter
RUN Rscript -e "install.packages(c('rstan', 'Rcpp'))" \
    -e "BiocManager::install('DirichletMultinomial')" \
    -e "BiocManager::install('davidaknowles/leafcutter/leafcutter', dependencies = TRUE, upgrade_dependencies = TRUE)" \
    -e "BiocManager::install('dzhang32/dasper')"
    
    
