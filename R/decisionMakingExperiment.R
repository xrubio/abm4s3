source("./decusionMaking.R")
library(utils)
library(foreach)
library(doParallel)
registerDoParallel(cores=6)


pb <- txtProgressBar(min = 1, max = length(popSize), style=3)
nsim=100

Results=foreach(r=1:30,.combine=cbind) %dopar%
{
    setTxtProgressBar(pb, k)
    replicate(nsim,main(nAgents=50,energyCost=25,maxEnergy=100,resourceGrowthRate=25,nSteps=1000,dimX=30,dimY=30,plot=FALSE,verbose=FALSE,radius=r)[1000])
}
close(pb)
save.image("experimentDecisionMakingResults.RData")
