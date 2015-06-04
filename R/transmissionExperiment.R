
source("./transmissionNewPrestige.R")
library(utils)
library(foreach)
library(doParallel)
registerDoParallel(cores=6)

popSize<-round(runif(100,10,500))
print("Running vertical Transmission...")
pb <- txtProgressBar(min = 1, max = length(popSize), style=3)

vertical.Results=foreach(k=1:length(popSize),.combine=c) %dopar%
{
    setTxtProgressBar(pb, k)
    main(nAgents=popSize[k],xDim=10,yDim=10,interactionRadius=1,
         moveDistance=1,timeSteps=1000,nTraits=3,transmissionType=c("vertical"),
         nTraitRange=c(0,1,2,3,4),prestigeIndex=1,replacementRate=0.1,
         innovationRate=0.01,plotSim=FALSE,verbose=FALSE)[1000]
}
close(pb)


print("Running encounter Transmission...")
pb <- txtProgressBar(min = 1, max = length(popSize), style=3)

encounter.Results=foreach(k=1:length(popSize),.combine=c) %dopar%
{
    setTxtProgressBar(pb, k)
    main(nAgents=popSize[k],xDim=10,yDim=10,interactionRadius=1,
         moveDistance=1,timeSteps=1000,nTraits=3,transmissionType=c("encounter"),
         nTraitRange=c(0,1,2,3,4),prestigeIndex=1,replacementRate=0.1,
         innovationRate=0.01,plotSim=FALSE,verbose=FALSE)[1000]
}
close(pb)


print("Running prestige Transmission...")
pb <- txtProgressBar(min = 1, max = length(popSize), style=3)

prestige.Results=foreach(k=1:length(popSize),.combine=c) %dopar%
{
    setTxtProgressBar(pb, k)
    main(nAgents=popSize[k],xDim=10,yDim=10,interactionRadius=1,
         moveDistance=1,timeSteps=1000,nTraits=3,transmissionType=c("prestige"),
         nTraitRange=c(0,1,2,3,4),prestigeIndex=1,replacementRate=0.1,
         innovationRate=0.01,plotSim=FALSE,verbose=FALSE)[1000]
}
close(pb)


print("Running conformist Transmission...")
pb <- txtProgressBar(min = 1, max = length(popSize), style=3)

conformist.Results=foreach(k=1:length(popSize),.combine=c) %dopar%
{
    setTxtProgressBar(pb, k)
    main(nAgents=popSize[k],xDim=10,yDim=10,interactionRadius=1,
         moveDistance=1,timeSteps=1000,nTraits=3,transmissionType=c("conformist"),
         nTraitRange=c(0,1,2,3,4),prestigeIndex=1,replacementRate=0.1,
         innovationRate=0.01,plotSim=FALSE,verbose=FALSE)[1000]
}
close(pb)

save.image("experimentTransmissionResults.RData")
