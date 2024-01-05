# protectedseas-statistics

## Run

- Remove `database.sqlite` to start from scratch
- Download spatial data to `shapes`
- Set H3 resolution and run `index_shapes.R`
- Check shape indexing errors in `shapes_errors`
- Download OBIS parquet snapshot
- Set H3 resolution and run `obis_extract.R`
- Download GBIF parquet snapshot
- Set H3 resolution and run `gbif_extract.R`
