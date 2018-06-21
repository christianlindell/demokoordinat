library(readxl)
library(spatial)
library(rgdal)
library(writexl)
library(tidyverse)


# Läs in koordinater i WGS84-format (det format som t.ex. används av Google-maps)

dfadresser <- tibble::tribble(
  ~lat,       ~lon,
  59.8051214,  17.6896049,
  59.7270467,  17.8089790,
  59.9013531,  17.0176058,
  59.9398745,  17.8720678,
  60.0347762,  17.3069286,
  59.9651196,  17.7671378,
  59.8408899,  17.6307211,
  59.5692486,  17.5310160,
  59.5402218,  17.4972200,
  59.7264353,  17.8079230
)


# Projection string for SWEREF99
SWEREF99TM <- "+proj=utm +zone=33 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"

# Skapa data frame med koordinater i  SWEREF99
# Om det blir fel, kolla så att jag inte kastat om longitud och latitud...
coordinates(dfadresser) = c("lon", "lat")
proj4string(dfadresser) = CRS("+proj=longlat +datum=WGS84")
koordSWEREF <- spTransform(dfadresser, CRS(SWEREF99TM))
dfadressSWEREF <- as_data_frame(koordSWEREF)

write_xlsx(dfadressSWEREF, path = "swereftest.xlsx")


# Vill man lägga på information från shape-filen om vilken kommun,
# tätort och län varje punkt ligger i kan man använda raster-paketets
# extract()-funktion. Koden, inkl. fria shape-filer från lantmäteriet
# kan laddas hem från https://github.com/christianlindell/demokoordinat

path <- getwd()

kommun <- readOGR(paste0(path, "/", "karta"),"ak_riks")
tatort <- readOGR(paste0(path, "/", "karta"), "mb_riks")

# extract data
dfdata_kommun <- data.frame(coordinates(dfadressSWEREF),
                          raster::extract(kommun, dfadressSWEREF))

dfdata_tatort <- data.frame(coordinates(dfadressSWEREF),
                          raster::extract(tatort, dfadressSWEREF))

# merge dfs

dfdata_kommun1 <- dfdata_kommun %>% 
  select(lon, lat, LANSNAMN, KOMMUNNAMN) %>% 
  mutate(concat = paste(lat,lon,sep="_")) %>% 
  distinct()

dfdata_tatort1 <- dfdata_tatort %>% 
  select(lon, lat, KATEGORI, NAMN1) %>% 
  mutate(concat = paste(lat,lon,sep="_")) %>%
  distinct()

dffinal <- merge(x=dfdata_tatort1[,c("concat","KATEGORI", "NAMN1")], y=dfdata_kommun1, by="concat")
dffinal <- dffinal %>% select(lon, lat, kommun=KOMMUNNAMN, lan=LANSNAMN, tatort=KATEGORI, tatort.namn=NAMN1)





