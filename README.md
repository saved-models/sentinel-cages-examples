# Example data management for 2011-2013 sentinel cages sampling exercise

These are a set of R scripts used to extract data for the sentinel cages examples.

## Example 1: Split cage data 

The first script (`bin/split_cages.R`) finds deployment bounds, outputs these in a CSV, and produces a CSV file per:

  - Season/year (e.g. S11 for spring 2011, A13 for autumn 2013)
  - Deployment date bounds (unique weekly deployments)
  - Cage number (not all cages appear in all deployments in a given season)
  
To deal with dates sensibly, it uses the R `lubridate` library. The dates are thus normalised and ordered. It also depends on some of the other R Tidyverse libraries like `dplyr` and `purrr`.

## Example 2: Locating nearest grid location to a given cage
  
The second script (`bin/find_nearest.R`) is a set of functions for finding the nearest location on a grid to a given cage location. The cage location is more precise than the grid locations in some of the density data submitted, so this is really just a demonstration of using Haversine distance to find the nearest eastings/northings (or latitude/longitude). There's a conversion between eastings/northings on the British National Grid to latitude/longitude.

It takes a single argument pointing to some set of eastings/northings in a target time series relating to model output.

This script further depends on the `sf` library as well as `geosphere` for calculating Haversine.


## Data

The R scripts are provided under GPLv3. Data in `contrib/` are from the [Loch Linnhe Biological Sampling Products 2011-2013](https://data.marine.gov.scot/dataset/loch-linnhe-biological-sampling-data-products-2011-2013-0) data package. These are provided under the Open Government License.
