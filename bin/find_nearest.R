#!/usr/bin/env Rscript

require(sf)
require(geosphere)
require(dplyr)

raw_args = commandArgs(trailingOnly=T)
if(length(raw_args) != 1)
    stop("Script takes single argument: path to raw CSV containing \"eastings\"/\"northings\"")


print(paste("Set of eastings/northings given in", raw_args[1]))
raw_locations = read.csv(raw_args[1])
all_locations = raw_locations |>
    dplyr::select(eastings, northings) |>
    unique() |>
    annotate_lon_lat()

stations_raw = read.csv("contrib/Sentinel_cage_station_info_6.csv")



annotate_lon_lat = function(df
                          , lab_e="eastings"   , lab_n="northings"
                          , lab_lon="longitude", lab_lat="latitude"
                          , crs=27700, pr=4326) {
    df_coordinates= sf::st_as_sf(df, coords=c(lab_e, lab_n), crs=crs) |>
        sf::st_transform(pr) |>
        sf::st_coordinates() |>
        as.data.frame()
    colnames(df_coordinates) = c(lab_lon, lab_lat)
    return(cbind(df, df_coordinates))
}

find_coords = function(lon_lat
                     , lab_lon_new="found.longitude", lab_lat_new="found.latitude"
                     , lab_eastings_new="found.eastings", lab_northings_new="found.northings"
                     , all_locs) {
    all_distances = geosphere::distHaversine(
        p1 = lon_lat
      , p2 = all_locs[,c("longitude","latitude")]
    )
    # shouldn't be more than one since we called unique() on sample_locations
    index   = match(min(all_distances), all_distances)
    nearest = all_locs[index,]
    # distHaversine always outputs 'longitude', 'latitude', by the looks of it
    target = list(nearest$longitude, nearest$latitude, nearest$eastings, nearest$northings)
    names(target) = c(lab_lon_new, lab_lat_new, lab_eastings_new, lab_northings_new)
    return(target)
}

annotate_nearest = function(df, col_lon, col_lat
                          , lab_lon_new="found.longitude", lab_lat_new="found.latitude"
                          , lab_eastings_new="found.eastings", lab_northings_new="found.northings"
                          , all_locs) {
    finder = \(k) find_coords(
        k, lab_lon_new, lab_lat_new, lab_eastings_new, lab_northings_new, all_locs=all_locs
    )
    annotation = apply(df[,c(col_lon,col_lat)], 1, finder) |> dplyr::bind_rows()
    return(cbind(df, annotation))
}

print(paste("Annotating stations data with nearest eastings/northings in", raw_args[1]))
# We MIGHT test the above annotate_lon_lat by annotating the stations file and comparing them:#
#stations_extra = stations_raw |>
#    annotate_lon_lat("Cage.easting", "Cage.northing", "Cage.lon.new", "Cage.lat.new") |>
#    annotate_nearest("Cage.lon.new", "Cage.lat.new", "Nearest.longitude", "Nearest.latitude", "Nearest.eastings", "Nearest.northings")
stations_extra = stations_raw |>
    annotate_nearest(col_lon="Cage.X.DD", col_lat="Cage.Y.DD"
                   , lab_lon_new="Nearest.longitude", lab_lat_new="Nearest.latitude"
                   , lab_eastings_new="Nearest.eastings", lab_northings_new="Nearest.northings"
                   , all_locs=all_locations)

print ("Writing annotated stations data to out/stations_nearest.csv")
stations_extra |>
    write.table("out/stations_nearest.csv", quote=T, row.names=F, sep=',', na='')
