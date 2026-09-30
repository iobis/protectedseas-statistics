# Statistics used in the IOC's State of the Ocean Report 2024 chapter "Biodiversity knowledge and threats on marine life: Assessing no-take zones as a refuge for marine species"

[![DOI](https://img.shields.io/badge/DOI-10.5281/zenodo.23063576-blue)](https://doi.org/10.5281/zenodo.23063576)
[![Products catalogue](https://raw.githubusercontent.com/iobis/badges/refs/heads/main/badges/obis-products_catalogue.svg)](https://products.obis.org/dataset/10-5281-zenodo-23063576)
[![IOC](https://raw.githubusercontent.com/iobis/badges/refs/heads/main/badges/ioc-hlo1_healthy_ocean.svg)](https://www.ioc.unesco.org/en/mission-and-objectives)

Statistics were calculated for each protected area as provided by [ProtectedSeas](https://protectedseas.net/). You can see the resulting report at [the UNESCO website](https://unesdoc.unesco.org/in/documentViewer.xhtml?v=2.1.196&id=p::usmarcdef_0000390054&file=/in/rest/annotationSVC/DownloadWatermarkedAttachment/attach_import_d73df27f-de59-4e05-be4a-f5ee80c17780%3F_%3D390054eng.pdf&locale=en&multi=true&ark=/ark:/48223/pf0000390054/PDF/390054eng.pdf#INT_833.24_State%20of%20ocean%20report_May2024_draft.indd%3A.207683%3A5829).

## Data preparation

### Configuration

- Configure H3 resolution and data sources in `common.R`
- Delete `storr` caches if necessary

### Index spatial data

Index all shapes to the configured H3 resolution and load into sqlite.

- Download spatial data to `shapes`
- Run `shapes_index.R` to index shapes and write to storr cache
- Run `shapes_sqlite.R` to load indexed shapes as well as site info into sqlite
- Check shape indexing errors in `shapes_errors`

### OBIS data

Index all OBIS data to the configured H3 resolution and load into sqlite. Write all OBIS taxa to RDS.

- Download OBIS parquet snapshot
- Run `obis_index.R` to index occurrences and write to storr cache
- Run `obis_sqlite.R` to load indexed occurrences into sqlite

### GBIF data

Index all GBIF data to the configured H3 resolution and load into sqlite. Write all GBIF taxa to RDS.

- Download GBIF parquet snapshot
- TODO TAXON MATCHING
- Run `gbif_index.R` to index occurrences and write to storr cache
- Run `gbif_taxa.R` to match and resolve all GBIF species names to accepted WoRMS names and write to RDS
- Run `gbif_sqlite.R` to load indexed occurrences with accepted names into sqlite

### Combine datasets

- Run `combine.R` to combine GBIF and OBIS occurrences into a single table
- Run `taxa.R` to get a full taxonomy table in sqlite

### Red List data

- Run `redlist.R` to fetch the IUCN red list species and write to RDS

## Upload to AWS

```
rm protectedseas.zip
zip -r -0 protectedseas.zip taxa.rds redlist.rds sites_storr database.sqlite shapes
aws s3 cp protectedseas.zip s3://obis-products/protectedseas/protectedseas.zip
```

## Download from AWS

This dataset contains the site information and shapefile, a [storr](https://richfitz.github.io/storr/articles/storr.html) cache with species lists by site ID including full taxonomy and red list category, an RDS file with OBIS as well as GBIF taxa, and a SQLite database with H3 indexed site shapes, OBIS occurrences, and marine GBIF occurrences.

https://obis-products.s3.amazonaws.com/protectedseas/protectedseas.zip

## Addtional data

### Marine World Heritate sites

- Run `mwhs_index.R` to index shapes and write to storr cache

### Add more H3 resolutions

- Run `h3_resolutions.R`
