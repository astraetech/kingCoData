#
#   Prepare the King County data
#
#***************************************************************************************************

 library(tidyverse)

 library(kingCoData)

 base_path <- 'c:/dropbox/andy/public/'
 data_path <- file.path(base_path, 'ready')
 end_year <- 2019

### Load Data --------------------------------------------------------------------------------------

# Parcel Data
par99_df <- read.csv(file.path(base_path, 'raw', 'parcel', 'parcel_1999.csv'))
parcur_df <- read.csv(file.path(base_path, 'raw', 'parcel', 'parcel_current.csv'))

# Parcel Data
rb99_df <- read.csv(file.path(base_path,  'raw', 'res_bldg', 'resbldg_1999.csv'))
rbcur_df <- read.csv(file.path(base_path, 'raw', 'res_bldg', 'resbldg_current.csv'))

# Tax Data
tax99_df <- readRDS(file.path(data_path, 'tax_1999.rds'))
taxcur_df <- readRDS(file.path(data_path, 'tax_current.rds'))

# Tax Data
geo99_df <- readRDS(file.path(data_path, 'geo_99.rds'))
geocur_df <- readRDS(file.path(data_path, 'geo_new.rds'))

# Changes
changes_df <- readRDS(file.path(data_path, 'major_changes.rds'))

# Sales
sales_df <- readRDS(file.path(data_path, 'sales.RDS'))

### Prepare Parcel, ResBldg and Tax Files ----------------------------------------------------------

 ## Parcel
par99_df <- par99_df %>%
  dplyr::select(Major, Minor, prop_type = PropType, area=Area, sub_area = SubArea,
                city = DistrictName, zoning = CurrentZoning, present_use = PresentUse,
                sqft_lot = SqFtLot, view_rainier = MtRainier, view_olympics = Olympics,
                view_cascades = Cascades, view_territorial = Territorial,
                view_skyline = SeattleSkyline, view_sound = PugetSound,
                view_lakewash = LakeWashington, view_lakesamm = LakeSammamish,
                view_otherwater = SmallLakeRiverCreek, view_other = OtherView,
                wfnt = WfntLocation, golf = AdjacentGolfFairway, greenbelt = AdjacentGreenbelt,
                noise_traffic = TrafficNoise) %>%
  utilAddPinx(.)

parcur_df <- parcur_df %>%
  dplyr::select(Major, Minor, prop_type = PropType, area=Area, sub_area = SubArea,
                city = DistrictName, zoning = CurrentZoning, present_use = PresentUse,
                sqft_lot = SqFtLot, view_rainier = MtRainier, view_olympics = Olympics,
                view_cascades = Cascades, view_territorial = Territorial,
                view_skyline = SeattleSkyline, view_sound = PugetSound,
                view_lakewash = LakeWashington, view_lakesamm = LakeSammamish,
                view_otherwater = SmallLakeRiverCreek, view_other = OtherView,
                wfnt = WfntLocation, golf = AdjacentGolfFairway, greenbelt = AdjacentGreenbelt,
                noise_traffic = TrafficNoise) %>%
  utilAddPinx(.)

 ## Res Building
rbcur_df <- rbcur_df %>%
  utilAddPinx(.) %>%
  dplyr::select(pinx, bldg_nbr = BldgNbr, units = NbrLivingUnits, zip = ZipCode, stories = Stories,
                grade = BldgGrade, sqft = SqFtTotLiving, sqft_1 = SqFt1stFloor,
                sqft_fbsmt = SqFtFinBasement, fbsmt_grade = FinBasementGrade,
                garb_sqft = SqFtGarageBasement, gara_sqft = SqFtGarageAttached,
                beds = Bedrooms, bath_half = BathHalfCount, bath_3qtr = Bath3qtrCount,
                bath_full = BathFullCount, condition = Condition,
                year_built = YrBuilt, year_reno = YrRenovated, view_util = ViewUtilization) %>%
  dplyr::group_by(pinx) %>%
  dplyr::mutate(bldgs = dplyr::n()) %>%
  dplyr::filter(bldgs == 1) %>%
  dplyr::filter(bldg_nbr == 1) %>%
  dplyr::ungroup() %>%
  dplyr::filter(units == 1)

rb99_df <- rb99_df %>%
  utilAddPinx(.) %>%
  dplyr::select(pinx, bldg_nbr = BldgNbr, units = NbrLivingUnits, stories = Stories,
                grade = BldgGrade, sqft = SqFtTotLiving, sqft_1 = SqFt1stFloor,
                sqft_fbsmt = SqFtFinBasement, fbsmt_grade = FinBasementGrade,
                garb_sqft = SqFtGarageBasement, gara_sqft = SqFtGarageAttached,
                beds = Bedrooms, bath_half = BathHalfCount, bath_3qtr = Bath3qtrCount,
                bath_full = BathFullCount, condition = Condition,
                year_built = YrBuilt, year_reno = YrRenovated, view_util = ViewUtilization)  %>%
  dplyr::group_by(pinx) %>%
  dplyr::mutate(bldgs = dplyr::n()) %>%
  dplyr::filter(bldgs == 1) %>%
  dplyr::filter(bldg_nbr == 1) %>%
  dplyr::ungroup() %>%
  dplyr::filter(units == 1)

### Add matching year ------------------------------------------------------------------------------

  # Simple year buit/Reno data
  rbs_df <- rb99_df %>%
    dplyr::select(pinx, yb99 = year_built, yr99 = year_reno) %>%
    dplyr::full_join(rbcur_df %>%
                       dplyr::select(pinx, yb19 = year_built, yr19 = year_reno),
                     by = 'pinx')

  # Add RBS to sales and filter by property type
  trim_df <- sales_df %>%
    inner_join(rbs_df, by = 'pinx') %>%
    dplyr::filter(property_type %in% c(2, 3, 10, 11))

### Split by match type and add data ---------------------------------------------------------------

  # No change
  nochg_df <- trim_df %>%
    dplyr::filter(!is.na(yb99) & !is.na(yb19) &
                    yb99 == yb19 & yr19 == 0) %>%
    dplyr::mutate(match_type = 'nochg',
                  match_year = end_year)

  x_df <- trim_df %>%
    dplyr::filter(!sale_id %in% nochg_df$sale_id)

  # Demolished
  demo_df <- x_df %>%
    dplyr::filter(is.na(yb19)) %>%
    dplyr::mutate(match_type = 'demo',
                  match_year = 1999)

  x_df <- x_df %>%
    dplyr::filter(!sale_id %in% demo_df$sale_id)

  # New construction
  new_df <- x_df %>%
    dplyr::filter(is.na(yb99)) %>%
    dplyr::mutate(match_type = ifelse(yb19 < 1999, 'miss99', 'new'),
                  match_year = end_year)

  x_df <- x_df %>%
    dplyr::filter(!sale_id %in% new_df$sale_id)

  # Rebuilt home
  rebuilt_df <- x_df %>%
    dplyr::filter(yb99 != yb19) %>%
    dplyr::mutate(match_type = ifelse(yb19 > sale_year, 'rebuilt - after',
                                      ifelse(yb19 < sale_year, 'rebuilt - before', 'rebuilt - ?')),
                  match_year = ifelse(match_type == 'rebuilt - after', end_year,
                                      ifelse(match_type == 'rebuilt - before', 1999, -1)))

  x_df <- x_df %>%
    dplyr::filter(!sale_id %in% rebuilt_df$sale_id)

  # Renovated
  reno_df <- x_df %>%
    dplyr::mutate(match_type = ifelse(yr19 > sale_year, 'reno - after',
                                      ifelse(yr19 < sale_year, 'reno - before', 'reno - ?')),
                  match_year = ifelse(match_type == 'reno - after', 1999,
                                      ifelse(match_type == 'reno - before',
                                             ifelse(yr19 < 1999, 1999, end_year), -1)))

### Join and Row Bind ------------------------------------------------------------------------------

 # Row Binds
  sale_df <- nochg_df %>%
    dplyr::bind_rows(., demo_df, new_df, rebuilt_df, reno_df) %>%
    dplyr::filter(match_year != -1)

  # Matched to 99
  sale99_df <- sale_df %>%
    dplyr::filter(match_year == 1999) %>%
    dplyr::select(-c(yb99, yr99, yb19, yr19)) %>%
    dplyr::left_join(., par99_df, by = 'pinx') %>%
    dplyr::left_join(., rb99_df, by = 'pinx') %>%
    dplyr::left_join(., tax99_df %>%
                       dplyr::select(-tax_year), by = 'pinx') %>%
    dplyr::left_join(., geo99_df %>%
                       dplyr::mutate(pinx = paste0('..', PIN)) %>%
                       dplyr::select(pinx, latitude, longitude), by = 'pinx')

 # Matched to 2019
  salecur_df <- sale_df %>%
    dplyr::filter(match_year == end_year) %>%
    dplyr::select(-c(yb99, yr99, yb19, yr19)) %>%
    dplyr::left_join(., parcur_df, by = 'pinx') %>%
    dplyr::left_join(., rbcur_df, by = 'pinx') %>%
    dplyr::left_join(., taxcur_df %>%
                     dplyr::select(-tax_year), by = 'pinx') %>%
    dplyr::left_join(., geocur_df %>%
                       dplyr::mutate(pinx = paste0('..', PIN)) %>%
                       dplyr::select(pinx, latitude, longitude), by = 'pinx')

 # Bind Together
 kingco_sales <- dplyr::bind_rows(sale99_df, salecur_df) %>%
   dplyr::select(-c(Major, Minor, prop_type)) %>%
   dplyr::filter(present_use %in% c(2, 6, 29)) %>%
   dplyr::filter(property_class == 8) %>%
   dplyr::filter(principal_use == 6) %>%
   dplyr::filter(!is.na(latitude)) %>%
   dplyr::filter(!is.na(land_val)) %>%
   dplyr::filter(sale_price > 50000) %>%
   dplyr::mutate(sale_date = as.Date(sale_date),
                 golf = ifelse(golf == 'Y', 1, 0),
                 greenbelt = ifelse(greenbelt == 'Y', 1, 0)) %>%
   dplyr::select(sale_id, pinx, sale_date, sale_price, sale_nbr, sale_warning,
                 join_status = match_type, join_year = match_year,
                 latitude, longitude, area, city, zoning,
                 present_use, land_val, imp_val,
                 year_built, year_reno, sqft_lot, sqft, sqft_1, sqft_fbsmt, grade, fbsmt_grade,
                 condition, stories, beds, bath_full, bath_3qtr, bath_half, garb_sqft, gara_sqft,
                 wfnt, golf, greenbelt, noise_traffic, view_rainier, view_olympics, view_cascades,
                 view_territorial, view_skyline, view_sound, view_lakewash, view_lakesamm,
                 view_otherwater, view_other)

### Write out data ---------------------------------------------------------------------------------

 usethis::use_data(kingco_sales, overwrite = T)

####################################################################################################
####################################################################################################
