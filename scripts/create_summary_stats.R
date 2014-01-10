#---------------------------------------------#
#---------------------------------------------#
# CREATE DESCRIPTIVE SUMMARY STATISTICS	    # 
#                                             #
# Authors: Nick Mader, Ian Matthew Morey,     # 
#		    and Emily Wiegand		    #  
#---------------------------------------------#
#---------------------------------------------#

## Set up workspace and designate/update file locations

  rm(list=ls())
  #myDir <- "/projects/Integrated_Evaluation_Youth_Support_Services"
  myDir <- "H:/Integrated Evaluation Project for YSS Providers"
  setwd(myDir)
  dataPath <- "./data/preprocessed-data/" # File path to locate and save data

  useScrambledData <- 0

## Load selected data

  try(detach(myData), silent=T)

  if (useScrambledData==1) {
    load(paste0(dataPath,"Scram.Rda"))
    myData <- Scram
    rm(Scram)
    myGraphOut <- paste0(myDir,"/demos/") 
  } else {
  	load("./data/preprocessed-data/CpsYss_PP13.Rda")
  	cNames <- colnames(CpsYss_PP13)
  	keepVars <- c("sid", "SchYear", "Stud_Tract", "schlid", "fGradeLvl", "grade_level",
                "Female", "disab", "fRace", grep("bRace", cNames, value=T), grep("bLunch", cNames, value=T),
                "readss", "mathss", "readgain", "mathgain", "readpl", "mathpl", "mathpl_ME", "readpl_ME", "mathss_pre", "readss_pre",
                "Pct_Attend", "Pct_Attend_pre", "bOnTrack", "bHsGrad",
                "Stud_X", "Stud_Y", grep("Tract_", cNames, value=T), "Stud_CcaNum", "Stud_CcaName",
                "fYssType", "fYssSite", "fAnyYss", "UsedYss") #"Pct_Absent", "Pct_Absent_pre",
      myData <- CpsYss_PP13[, keepVars]
	  myGraphOut <- paste0(myDir,"/output/")
      rm(CpsYss_PP13)} 

  attach(myData)
  

## Select variables to summarize

  cNames <- colnames(myData)
  ctsVars <- c("mathss", "readss", "mathgain", "readgain", "mathpl_ME", "readpl_ME", "Pct_Attend", grep("bRace", cNames, value=T),grep("bLunch", cNames, value=T), grep("Tract_", cNames, value=T))  
  catVars <- c("mathpl", "readpl", "fGradeLvl", "fRace")
  #ctsVars <- c("mathss", "readss")
  
## Calculate summary statistics for continuous measures
    
  ctsMean_byAny     <- aggregate(myData[, ctsVars], list(fAnyYss),               mean, na.rm = T)
  ctsMean_byAnyGr   <- aggregate(myData[, ctsVars], list(fAnyYss, fGradeLvl),    mean, na.rm = T)
  ctsMean_bySite    <- aggregate(myData[, ctsVars], list(fYssSite),            mean, na.rm = T)
  ctsMean_bySiteGr  <- aggregate(myData[, ctsVars], list(fYssSite, fGradeLvl), mean, na.rm = T)
  ctsMean_bySch     <- aggregate(myData[, ctsVars], list(schlid),                mean, na.rm = T)
  ctsMean_bySchGr   <- aggregate(myData[, ctsVars], list(schlid, fGradeLvl),     mean, na.rm = T)
  
  colnames(ctsMean_byAny)[1]    <- "Site"; ctsMean_byAny$Grade <- "All"
  colnames(ctsMean_byAnyGr)[1]  <- "Site"; colnames(ctsMean_byAnyGr)[2] <- "Grade"
  colnames(ctsMean_bySite)[1]   <- "Site"; ctsMean_bySite$Grade <- "All"
  colnames(ctsMean_bySiteGr)[1] <- "Site"; colnames(ctsMean_bySiteGr)[2] <- "Grade"
  colnames(ctsMean_bySch)[1]    <- "Site"; ctsMean_bySch$Grade <- "All"
  colnames(ctsMean_bySchGr)[1]  <- "Site"; colnames(ctsMean_bySchGr)[2] <- "Grade"

## Combine summary statistics across different measures into one data frame
  
  statDFs <- list(ctsMean_bySiteGr,ctsMean_byAny,ctsMean_byAnyGr,ctsMean_bySite,ctsMean_bySch,ctsMean_bySchGr)
  siteAsChar <- function(df){df$Site <- as.character(df$Site); return(df)}
  statDFs2 <- lapply(statDFs,siteAsChar)
  ctsMeans <- do.call("rbind", statDFs2)
  
## Calculate summary statistics for categorical measures
    
###### ERW: Return to rework this section once I see what is needed for the graphs

  CatCalc <- function(v){
    table <- as.data.frame(prop.table(table(fAnyYss, myData[, v]), 1))
    table[, v] <- paste0(v,"_",table[, 2])
    #out <- cast(table, formula = as.formula(paste0("fAnyYss ~ ",v)), value="Freq")
    return(table)}



  x <- CatCalc(cbind(fAnyYss,mathpl,readpl))
  z <- aggregate(cbind(mathpl, readpl), list(fAnyYss), CatCalc)

  ds <- function(x){ deparse(substitute(x))}
    
  myFun <- function(v){
    table <- as.data.frame(prop.table(table(v)))
    #table[, ds(v)] <- ds(v) %&% "_" %&% table[, 1]
    #out <- cast(table, formula = as.formula(". ~ " %&% ds(v)), value="Freq")
    #return(out)
    return(table)
  }
  z <- aggregate(cbind(mathpl, readpl), list(fAnyYss), CatCalc2)
    
  simplerFun <- function(v){
    x <- prop.table(table(v))        
    dimnames(x)$v <- dimnames(x)$v
  }
  aggregate(cbind(mathpl, readpl), list(fAnyYss), simplerFun)
    
  GrDist <- table(fAnyYss, fGradeLvl)
  GrDistProp <- prop.table(GrDist, 1)  
  GrDistPropL <- as.data.frame(GrDistProp)  
  if (s != "All") {
    p <- prop.table(table(fGradeLvl[fShortSite==s]))
    df <- data.frame(cbind(s, data.frame(p)))
    colnames(df) <- colnames(GrDistPropL)
    GrDistPropL <- rbind(GrDistPropL, df)
  }
  
  
## Create average characteristics for representative peers in same schools
  
 # Get Column %s
  SchProp_bySite <- prop.table(table(schlid, fYssSite), 2) # Get Column %s
  SchProp_byAny  <- prop.table(table(schlid, fAnyYss), 2) # Get Column %s
    
 # Create function to take average conditional on site designation and variable
  PeerAvg_forSV <- function(s, v) {
    nonNAN <- !is.na(ctsMean_bySch[, v])
    cbind(s, v, weighted.mean(ctsMean_bySch[nonNAN, v], PropData[nonNAN, s]))
  }  
    
  ### Calculate Averages by Yss Site ###
  
  PropData <- SchProp_bySite
  ByLvls <- levels(fShortSite)
  PeerAvgs_bySite <- t(mapply(PeerAvg_forSV,
                                         rep(ByLvls,  length(ctsVars)),
                                         rep(ctsVars, each=length(ByLvls))
                                        ) )
  rownames(PeerAvgs_bySite) <- NULL
  PeerAvgs_bySite <- data.frame(PeerAvgs_bySite)
  PeerAvgs_bySite$X3 <- as.numeric(levels(PeerAvgs_bySite$X3)[PeerAvgs_bySite$X3])
  ctsMean_bySiteSchPeer <- cast(PeerAvgs_bySite, X1 ~ X2, value = "X3")
  colnames(ctsMean_bySiteSchPeer)[1] <- "Site"
  ctsMean_bySiteSchPeer$Site <- ctsMean_bySiteSchPeer$Site %&% "\nSch-Based Peers"
  ctsMean_bySiteSchPeer$Grade <- "All"
    
  ### Calculate Averages by Any Yss ###
  
  PropData <- SchProp_byAny
  ByLvls <- levels(fAnyYss)
  PeerAvgs_byAny <- t(mapply(PeerAvg_forSV,
                                         rep(ByLvls,  length(ctsVars)),
                                         rep(ctsVars, each=length(ByLvls))
                                        ) )
  rownames(PeerAvgs_byAny) <- NULL
  PeerAvgs_byAny <- data.frame(PeerAvgs_byAny)
  PeerAvgs_byAny$X3 <- as.numeric(levels(PeerAvgs_byAny$X3)[PeerAvgs_byAny$X3])
  ctsMean_byAnySchPeer <- cast(PeerAvgs_byAny, X1 ~ X2, value = "X3")
  colnames(ctsMean_byAnySchPeer)[1] <- "Site"
  ctsMean_byAnySchPeer$Site <- ctsMean_byAnySchPeer$Site %&% "\nSch-Based Peers"
  ctsMean_byAnySchPeer$Grade <- "All"
  
  #---------------
  ### SAVE RESULTS
  #---------------
  
if (useScrambledData==1) { 
  save(ctsMeans,    file = paste0(dataPath,"ctsMeans","_DEMO.Rda"))
} else {  
  save(ctsMeans,    file = paste0(dataPath,"ctsMean_byAny.Rda"))
  save(myData, file = paste0(dataPath, "subset_CpsYss_PP13.Rda"))
}
