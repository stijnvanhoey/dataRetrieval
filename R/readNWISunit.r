#' Raw Data Import for Instantaneous USGS NWIS Data
#'
#' Imports data from NWIS web service. This function gets the data from here: \url{http://waterservices.usgs.gov/}
#' A list of parameter codes can be found here: \url{http://nwis.waterdata.usgs.gov/nwis/pmcodes/}
#' A list of statistic codes can be found here: \url{http://nwis.waterdata.usgs.gov/nwis/help/?read_file=stat&format=table}
#'
#' @param siteNumbers string USGS site number (or multiple sites).  This is usually an 8 digit number
#' @param parameterCd string USGS parameter code.  This is usually an 5 digit number.
#' @param startDate string starting date for data retrieval in the form YYYY-MM-DD.
#' @param endDate string ending date for data retrieval in the form YYYY-MM-DD.
#' @param tz string to set timezone attribute of datetime. Default is an empty quote, which converts the 
#' datetimes to UTC (properly accounting for daylight savings times based on the data's provided tz_cd column).
#' Possible values to provide are "America/New_York","America/Chicago", "America/Denver","America/Los_Angeles",
#' "America/Anchorage","America/Honolulu","America/Jamaica","America/Managua","America/Phoenix", and "America/Metlakatla"
#' @keywords data import USGS web service
#' @return A data frame with the following columns:
#' \tabular{lll}{
#' Name \tab Type \tab Description \cr
#' agency \tab character \tab The NWIS code for the agency reporting the data\cr
#' site \tab character \tab The USGS site number \cr
#' datetime \tab POSIXct \tab The date and time of the value converted to UTC \cr 
#' tz_cd \tab character \tab The time zone code for datetime \cr
#' code \tab character \tab Any codes that qualify the corresponding value\cr
#' value \tab numeric \tab The numeric value for the parameter \cr
#' }
#' Note that code and value are repeated for the parameters requested. The names are of the form 
#' X_D_P_S, where X is literal, 
#' D is an option description of the parameter, 
#' P is the parameter code, 
#' and S is the statistic code (if applicable).
#' 
#' There are also several useful attributes attached to the data frame:
#' \tabular{lll}{
#' Name \tab Type \tab Description \cr
#' url \tab character \tab The url used to generate the data \cr
#' siteInfo \tab data.frame \tab A data frame containing information on the requested sites \cr
#' variableInfo \tab data.frame \tab A data frame containing information on the requested parameters \cr
#' statisticInfo \tab data.frame \tab A data frame containing information on the requested statistics on the data \cr
#' queryTime \tab POSIXct \tab The time the data was returned \cr
#' }
#' 
#' @seealso \code{\link{renameNWISColumns}}, \code{\link{importWaterML1}}
#' @export
#' @examples
#' siteNumber <- '05114000'
#' parameterCd <- '00060'
#' startDate <- "2014-10-10"
#' endDate <- "2014-10-10"
#' # These examples require an internet connection to run
#' rawData <- readNWISuv(siteNumber,parameterCd,startDate,endDate)
#' 
#' timeZoneChange <- readNWISuv(c('04024430','04024000'),parameterCd,
#'          "2013-11-03","2013-11-03")
#' firstSite <- timeZoneChange[timeZoneChange$site_no == '04024430',]
readNWISuv <- function (siteNumbers,parameterCd,startDate="",endDate="", tz=""){  
  
  url <- constructNWISURL(siteNumbers,parameterCd,startDate,endDate,"uv",format="xml")

  data <- importWaterML1(url,asDateTime=TRUE,tz=tz)

  return (data)
}

#' Reads peak flow data from NWISweb.
#' 
#' 
#' 
#' @param siteNumber string USGS site number.  This is usually an 8 digit number
#' @param startDate string starting date for data retrieval in the form YYYY-MM-DD.
#' @param endDate string ending date for data retrieval in the form YYYY-MM-DD.
#' @export
#' @examples
#' siteNumber <- '01594440'
#' data <- readNWISpeak(siteNumber)
readNWISpeak <- function (siteNumber,startDate="",endDate=""){  
  
  # Doesn't seem to be a peak xml service
  url <- constructNWISURL(siteNumber,NA,startDate,endDate,"peak")
  
  data <- importRDB1(url, asDateTime=FALSE)
    
  return (data)
}

#' Reads the current rating table for an active USGS streamgage.
#' 
#' 
#' 
#' @param siteNumber string USGS site number.  This is usually an 8 digit number
#' @param type string can be "base", "corr", or "exsa"
#' @export
#' @examples
#' siteNumber <- '01594440'
#' data <- readNWISrating(siteNumber, "base")
#' attr(data, "RATING")
readNWISrating <- function (siteNumber,type="base"){  
  
  # No rating xml service 
  url <- constructNWISURL(siteNumber,service="rating",ratingType = type)
    
  data <- importRDB1(url, asDateTime=FALSE)
  
  if(type == "base") {
    Rat <- grep("//RATING ", comment(data), value=TRUE, fixed=TRUE)
    Rat <- sub("# //RATING ", "", Rat)
    Rat <- scan(text=Rat, sep=" ", what="")
    attr(data, "RATING") <- Rat
  }
  
  return (data)
}

#'Reads surface-water measurement data from NWISweb.
#'
#'
#'
#' @param siteNumber string USGS site number.  This is usually an 8 digit number
#' @param startDate string starting date for data retrieval in the form YYYY-MM-DD.
#' @param endDate string ending date for data retrieval in the form YYYY-MM-DD.
#' @param tz string to set timezone attribute of datetime. Default is an empty quote, which converts the 
#' datetimes to UTC (properly accounting for daylight savings times based on the data's provided tz_cd column).
#' Possible values to provide are "America/New_York","America/Chicago", "America/Denver","America/Los_Angeles",
#' "America/Anchorage","America/Honolulu","America/Jamaica","America/Managua","America/Phoenix", and "America/Metlakatla"
#' @export
#' @examples
#' siteNumber <- '01594440'
#' data <- readNWISmeas(siteNumber)
readNWISmeas <- function (siteNumber,startDate="",endDate="", tz=""){  
  
  # Doesn't seem to be a WaterML1 format option
  url <- constructNWISURL(siteNumber,NA,startDate,endDate,"meas")
  
  data <- importRDB1(url,asDateTime=FALSE,tz=tz)
  
  if("diff_from_rating_pc" %in% names(data)){
    data$diff_from_rating_pc <- as.numeric(data$diff_from_rating_pc)
  }
  
  return (data)
}

#' Reads groundwater level measurements from NWISweb.
#'
#' Reads groundwater level measurements from NWISweb. Mixed date/times come back from the service 
#' depending on the year that the data was collected. 
#'
#' @param siteNumbers string USGS site number (or multiple sites).  This is usually an 8 digit number
#' @param startDate string starting date for data retrieval in the form YYYY-MM-DD.
#' @param endDate string ending date for data retrieval in the form YYYY-MM-DD.
#' @return A data frame with the following columns:
#' \tabular{lll}{
#' Name \tab Type \tab Description \cr
#' agency \tab character \tab The NWIS code for the agency reporting the data\cr
#' site \tab character \tab The USGS site number \cr
#' datetime \tab character \tab The date and time of the value as a character \cr 
#' tz_cd \tab character \tab The time zone code for datetime \cr
#' code \tab character \tab Any codes that qualify the corresponding value\cr
#' value \tab numeric \tab The numeric value for the parameter \cr
#' }
#' Note that code and value are repeated for the parameters requested. The names are of the form 
#' X_D_P_S, where X is literal, 
#' D is an option description of the parameter, 
#' P is the parameter code, 
#' and S is the statistic code (if applicable).
#' 
#' There are also several useful attributes attached to the data frame:
#' \tabular{lll}{
#' Name \tab Type \tab Description \cr
#' url \tab character \tab The url used to generate the data \cr
#' siteInfo \tab data.frame \tab A data frame containing information on the requested sites \cr
#' variableInfo \tab data.frame \tab A data frame containing information on the requested parameters \cr
#' statisticInfo \tab data.frame \tab A data frame containing information on the requested statistics on the data \cr
#' queryTime \tab POSIXct \tab The time the data was returned \cr
#' }
#' 
#' @seealso \code{\link{renameNWISColumns}}, \code{\link{importWaterML1}}
#' @export
#' @examples
#' siteNumber <- "434400121275801"
#' data <- readNWISgwl(siteNumber, '','')
#' sites <- c("434400121275801", "375907091432201")
#' data2 <- readNWISgwl(sites, '','')
readNWISgwl <- function (siteNumbers,startDate="",endDate=""){  
  
  url <- constructNWISURL(siteNumbers,NA,startDate,endDate,"gwlevels",format="wml1")
  data <- importWaterML1(url,asDateTime=FALSE)
  return (data)
}

