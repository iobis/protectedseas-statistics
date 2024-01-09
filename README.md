# protectedseas-statistics

## Run

### Configuration

- Configure H3 resolution and data sources in `common.R`
- Delete `storr` caches if necessary

### Index spatial data

Index all shapes to the configured H3 resolution and load into sqlite.

- Download spatial data to `shapes`
- Run `shapes_index.R`
- Run `shapes_sqlite.R`
- Check shape indexing errors in `shapes_errors`

### OBIS data

Index all OBIS data to the configured H3 resolution and load into sqlite. Write all OBIS taxa to RDS.

- Download OBIS parquet snapshot
- Run `obis_index.R`
- Run `obis_taxa.R`

### GBIF data

Index all GBIF data to the configured H3 resolution and load into sqlite. Write all GBIF taxa to RDS.

- Download GBIF parquet snapshot
- Run `gbif_index.R`
- Run `gbif_sqlite.R` (TODO: order of scripts not correct, refactor)
- Run `gbif_taxa.R`

### Red List data

- Run `redlist.R`

### Query dataset

- Run `indexes.R`
- Run `query.R`
