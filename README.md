# Automated aberrant and differential splicing analysis

# Check version of leafcutter and dasper installed

```
# you may need to replace "docker" with "docker run"
docker run dzhang32/auto_splice:0.1 Rscript -e "packageVersion('leafcutter')"
docker run dzhang32/auto_splice:0.1 Rscript -e "packageVersion('dasper')"
```
