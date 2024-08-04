#!/usr/bin/env Rscript

require(dplyr)
require(hms)
require(lubridate)
require(purrr)
require(tibble)

get_ts = function(d, t, local = "Europe/London", .f=lubridate::ymd) {
    return(lubridate::ymd_hms(paste(.f(d), hms::hms(hours=t)), tz=local))
}
get_season_str = function(dep_date) {
    year  = lubridate::year(dep_date)
    month = lubridate::month(dep_date)
    if (month < 06) season = "s"
    else            season = "a"
    return(paste(season, substr(year, 3, 4), sep=''))
}
get_bound_str = function(dep, rec) {
    return(paste("deployment_", dep, "_", rec, sep=''))
}

print("Loading sentinel cages sampling data")
sentinel_cages_raw = read.csv("contrib/Sentinel_cage_sampling_info_update_01122022.csv")

print("Grouping by deployment and recovery date")
sentinel_cages_grouped = sentinel_cages_raw |>
    dplyr::mutate(Deployment.date = lubridate::dmy(Deployment.date)
                , Recovery.date = lubridate::dmy(Recovery.date)) |>
    dplyr::group_by(Deployment.date, Recovery.date)

print("Summarising after grouping")
sentinel_cages_summarised = sentinel_cages_grouped |>
    dplyr::group_by(Deployment.date, Recovery.date, Cage.Number) |>
    dplyr::summarise() |>
    dplyr::group_by(Deployment.date, Recovery.date) |>
    dplyr::summarise(cages = list(Cage.Number)) |>
    dplyr::mutate(cages = purrr::map_chr(cages, ~paste(.x, collapse=', ')))




write_by_cage = function(parent_dir, cage_tab, append_dep=F) {
    cage_id = unique(cage_tab$Cage.Number)
    #print(paste("Cage ID was", cage_id))
    if (append_dep)
        fp = paste("out", "/", parent_dir, "/", parent_dir, "_cage_", cage_id, ".csv", sep='')
    else
        fp = paste("out", "/", parent_dir, "/", "cage_", cage_id, ".csv", sep='')
    write.table(cage_tab, fp, quote=T, row.names=F, sep=',', na='', )
    print(paste("Wrote", fp))
}

split_by_cage = function(tab) {
    date_dep = unique(tab$Deployment.date)
    date_rec = unique(tab$Recovery.date)
    
    parent_dir = get_bound_str(date_dep, date_rec)
    
    if(!(dir.exists(paste("out", parent_dir, sep='/'))))
       dir.create(paste("out", parent_dir, sep='/'))
    #print(paste("Parent directory was", parent_dir))
    tab |>
        dplyr::group_by(Cage.Number) |> 
        dplyr::group_split() |> 
        lapply(\(gr) write_by_cage(parent_dir, gr, append_dep=T))
    fp_main = paste("out", parent_dir, "all_cages.csv", sep='/')
    write.table(tab, fp_main, quote=T, row.names=F, sep=',', na='')
    print(paste("Wrote cage data in", parent_dir))
}

print("Splitting grouped data")
deployments_raw = sentinel_cages_grouped |>
    dplyr::group_split()

print("Writing splitted data as CSVs")
# Write raw deployment/cage CSVs
written_split = deployments_raw |> lapply(split_by_cage)



extract_bounds = function(tab) {
    Deployment.date = unique(tab$Deployment.date)
    Recovery.date   = unique(tab$Recovery.date)
    bounds = get_bound_str(Deployment.date, Recovery.date)
    season = get_season_str(Deployment.date)
    tibble::tibble_row(Deployment.date, Recovery.date, bounds, season)
}

print("Extracting bounds and arranging by season")
deployment_bounds = deployments_raw |> 
    lapply(extract_bounds) |>
    dplyr::bind_rows() |>
    #dplyr::mutate(Recovery.date.prev = lubridate::ymd(Recovery.date) - 1) |>
    dplyr::arrange(season)

print("Writing deployment bounds CSV")
written_deployment_bounds = deployment_bounds |>
    write.table("out/deployment_bounds.csv", quote=T, row.names=F, sep=',', na='')
