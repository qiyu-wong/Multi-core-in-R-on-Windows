library(parallel) 
library(Matrix)

## Define the hack
mclapply.hack <- function(...) {
  ## Create a cluster
  size.of.list <- length(list(...)[[1]])
  cl <- makeCluster( min(size.of.list, detectCores()) )
  ## Find out the names of the loaded packages 
  loaded.package.names <- c(
    ## Base packages
    sessionInfo()$basePkgs,
    ## Additional packages
    names( sessionInfo()$otherPkgs ))
  tryCatch( {
    ## Copy over all of the objects within scope to
    ## all clusters. 
    this.env <- environment()
    while( identical( this.env, globalenv() ) == FALSE ) {
      clusterExport(cl,
                    ls(all.names=TRUE, env=this.env),
                    envir=this.env)
      this.env <- parent.env(environment())
    }
    clusterExport(cl,
                  ls(all.names=TRUE, env=globalenv()),
                  envir=globalenv())
    
    ## Load the libraries on all the clusters
    ## N.B. length(cl) returns the number of clusters
    parLapply( cl, 1:length(cl), function(xx){
      lapply(loaded.package.names, function(yy) {
        require(yy , character.only=TRUE)})
    })
    
    ## Run the lapply in parallel 
    return( parLapply( cl, ...) )
  }, finally = {        
    ## Stop the cluster
    stopCluster(cl)
  })
}
## Warn the user if they are using Windows
if( Sys.info()[['sysname']] == 'Windows' ){
  message(paste(
    "\n", 
    "   *** Microsoft Windows detected ***\n",
    "   \n",
    "   For technical reasons, the MS Windows version of mclapply()\n",
    "   is implemented as a serial function instead of a parallel\n",
    "   function.",
    "   \n\n",
    "   As a quick hack, we replace this serial version of mclapply()\n",
    "   with a wrapper to parLapply() for this R session. Please see\n\n",
    "     http://www.stat.cmu.edu/~nmv/2014/07/14/implementing-mclapply-on-windows \n\n",
    "   for details.\n\n"))
}
## If the OS is Windows, set mclapply to the
## the hackish version. Otherwise, leave the
## definition alone. 
lapply <- switch( Sys.info()[['sysname']],
                  Windows = {mclapply.hack}, 
                  Linux   = {mclapply},
                  Darwin  = {mclapply})

#mclapply <- switch( Sys.info()[['sysname']],
#                    Windows = {mclapply.hack}, 
#                    Linux   = {mclapply},
#                    Darwin  = {mclapply})

#system.time( serial.output <- lapply(seq_len(nrow(df)),function(i) t(df[i,]))) 
# user  system elapsed 
# 50.37    0.56   51.22 

#system.time( par.output <- mclapply(seq_len(nrow(df)),function(i) t(df[i,]))) 
# user  system elapsed 
# 4.19    3.73   33.44

#all.equal( serial.output, par.output )
# [1] TRUE

#source("C:/Users/10331/OneDrive/Desktop/Social Network Analytics/Multi-core.r", echo = TRUE)

#Source: https://www.r-bloggers.com/2014/07/implementing-mclapply-on-windows-a-primer-on-embarrassingly-parallel-computation-on-multicore-systems-with-r/
