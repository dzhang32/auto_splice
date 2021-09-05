# Automated aberrant and differential splicing analysis

## Contents

This repository contains the instructions to create the [auto_splice docker image](https://hub.docker.com/repository/docker/dzhang32/auto_splice). This docker image contains: 
 
  1. A working installation of [leafcutter](https://github.com/davidaknowles/leafcutter) and [dasper](https://github.com/dzhang32/dasper). This includes the `leafcutter` dependencies `regtools` and `samtools` in the directory `/tools/`.
  2. An ".exons" file created by applying the leafcutter script [gtf_to_exons.R](http://davidaknowles.github.io/leafcutter/articles/Usage.html#step-3--differential-intron-excision-analysis) to the [Ensembl v104 GTF](http://ftp.ensembl.org/pub/release-104/gtf/homo_sapiens/Homo_sapiens.GRCh38.104.gtf.gz). This is stored in the directory `/data/gtf/`.

## Check version of leafcutter and dasper installed

```
# you may need to replace "docker" with "sudo docker"
docker run dzhang32/auto_splice:0.1 Rscript -e "packageVersion('leafcutter')"
docker run dzhang32/auto_splice:0.1 Rscript -e "packageVersion('dasper')"
```
