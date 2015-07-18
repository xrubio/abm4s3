source("./decisionMaking.R")
#source("./decisionMaking2.R") #with offspring random displacement

library(utils)
library(foreach)
library(doParallel)
registerDoParallel(cores=6)


pb <- txtProgressBar(min = 1, max = 30, style=3)
nsim=100

Results=foreach(r=1:30,.combine=cbind) %dopar%
{
    setTxtProgressBar(pb, r)
    replicate(nsim,main(nAgents=50,energyCost=25,maxEnergy=100,resourceGrowthRate=25,nSteps=5000,dimX=30,dimY=30,plot=FALSE,verbose=FALSE,radius=r)[5000])
}


close(pb)
save.image("experimentDecisionMakingResults.RData")



#save.image("experimentDecisionMakingResults2.RData") #with offspring random displacement


# Single Setting Fast Run #
nsim=100
pb <- txtProgressBar(min = 1, max = nsim, style=3)

Results=foreach(s=1:nsim,.combine=c) %dopar%
{
    setTxtProgressBar(pb, s)
    main(nAgents=50,energyCost=25,maxEnergy=100,resourceGrowthRate=25,nSteps=1000,dimX=30,dimY=30,plot=FALSE,verbose=FALSE,radius=1)[1000]
}
close(pb)
