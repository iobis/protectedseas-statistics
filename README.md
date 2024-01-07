# protectedseas-statistics

## Run

- Configure H3 resolution and data sources in `common.R`
- Download spatial data to `shapes`
- Delete `storr` caches if necessary
- Run `index_shapes.R`
- Check shape indexing errors in `shapes_errors`
- Download OBIS parquet snapshot
- Run `obis_extract.R`
- Download GBIF parquet snapshot
- Run `gbif_extract.R`
- Run `gbif_sqlite.R`
