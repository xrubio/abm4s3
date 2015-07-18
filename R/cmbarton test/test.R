
#Read Resource Raster
raster=as.matrix(read.csv("~/github/abm4s3/R/cmbarton test/raster.csv",sep=";",header=F))
colnames(raster)=NULL




testFun<-function(nAgents,experiment=c(0,1,2),resource=raster)
{
    ## Experiment 0 (Default)
    ## Experiment 1 (No Reproduction)
    ## Experiment 2 (No Reproduction + No Growth)
    ##Define Fixed Parameters
    energyCost=25;maxEnergy=100;resourceGrowthRate=25;
    nSteps=1000;dimX=10;dimY=10;radius=1
    verbose=FALSE

    
    ## Setup Simulation
    population=rep(0,nSteps) #placeholder for recording population size 
    maxResource=resource
    agents=data.frame(energy=rep(maxEnergy/2,nAgents),
            x=ceiling(runif(nAgents,0,dimX)),y=ceiling(runif(nAgents,0,dimX)))
    if(verbose==TRUE){pb <- txtProgressBar(min = 1, max = nSteps, style = 3)}


for (t in 1:nSteps)
            {

                #STEP 1: Agents Move to the cell with highest energy within its neighbourhood#           
                for (a in 1:nrow(agents))
                            {
    
                                agents[a,2:3]=neighbourhood(xcor=agents$x[a],ycor=agents$y[a],
                                                  xLimit=c(1,dimX),yLimit=c(1,dimY),
                                                  resourceMatrix=resource,radius=radius)                             
                            }
                
                #STEP 2: Agents Collect Energy from current cell, after randomising order of exectution      
                
                newOrder=sample(1:nrow(agents)) 
                agents=agents[newOrder,]  #shuffle agent order
                
                  for (a in 1:nrow(agents))
                            {              
                                        #agents consume
                                collection = maxEnergy-agents$energy[a] #max possible collection
                                energyInCell = resource[agents$x[a],agents$y[a]] #available ammount of energy
                                collected = min(energyInCell, maxEnergy - agents$energy[a])[1]
                                resource[agents$x[a],agents$y[a]]=resource[agents$x[a],agents$y[a]]-collected
                                agents$energy[a]=agents$energy[a]+collected
                            }
                
              
                ##STEP 3: Agents make a copy of themselves if their energy is equal to maxEnergy

                if (experiment==0) #Reproduction only in experiment 0
                    {
                        if(any(agents$energy==maxEnergy))
                            {
                                parents=which(agents$energy==maxEnergy)
                                agents$energy[parents]=maxEnergy/2
                                offspring=agents[parents,]
                                offspring$energy=offspring$energy+energyCost #to ensure offspring don't spend energy
                                agents<-rbind(agents,offspring)
                            }
                    }

                #STEP 3: Spend Energy#
                agents$energy=agents$energy-energyCost

                #STEP 4: Death#
                if(any(agents$energy<=0))
                    {
                        death=which(agents$energy<=0)
                        if(length(death)==nrow(agents))
                            {
                                agents=agents[-death,]
                               # print("extinction!")
                                if (experiment==2)
                                    {
                                        return(t)
                                    }
                                return(population[t])
                            }
                        agents=agents[-death,]                     
                    }
                  

                #STEP 5: Resource Growth#
                if (experiment!=2) #Resource growth all except for experiment 2
                    {

                        resource=resource+resourceGrowthRate
                        index=which((resource-maxResource)>0,arr.ind=TRUE)
                        resource[index]=maxResource[index]
                    }
                
                #Record Population Size:
                population[t]=nrow(agents)                

                if(verbose==TRUE){setTxtProgressBar(pb, t)}
            }
                    return(population[t])

            }






#utility functions #
neighbourhood<-function(xcor,ycor,xLimit,yLimit,resourceMatrix,radius)
{
    step=-radius:radius
    xcor1=xcor+step
    ycor1=ycor+step
    address=expand.grid(x=xcor1,y=ycor1)
    noMove=c(xcor,ycor)

    if(sum((address$x<xLimit[1]|address$x>xLimit[2]),na.rm=TRUE)>0){address[which(address$x<xLimit[1]|address$x>xLimit[2]),]=NA}
    if(sum((address$y<yLimit[1]|address$y>yLimit[2]),na.rm=TRUE)>0){address[which(address$y<yLimit[1]|address$y>yLimit[2]),]=NA}


    destinationResource=apply(address,1,function(x,y){
        if(!is.na(x[1]))
            {return(y[x[1],x[2]])}
        if(is.na(x[1]))
            return(NA)},y=resourceMatrix)

    if (all(destinationResource==0,na.rm=TRUE)) {return(noMove)}
    else
        {
        goto=which(destinationResource==max(destinationResource,na.rm=TRUE))
        #if(length(goto)>1){goto=sample(goto,size=1)}
        if(length(goto)>1){goto=goto[1]} #got to top left

        finaladdress=address[goto,]        
        return(finaladdress)
    }
}
