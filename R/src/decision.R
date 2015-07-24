###############################################################
## ~Decision Making Model~
##                                        
## Parameters:                                       
## dimX ::: x limit of the world (note that this will be the rows in the resource matrix)
## dimY ::: y limit of the world (note that this will be the columns in the resource matrix)
## nAgents ::: Number of agents at initialisation                                        
## nSteps ::: Number of timesteps in the model
## resourceGrowthRate ::: Amount increase of resources per timeStep
## maxEnergy ::: maximum possible storable energy. Also maximum possible cell values in the resource scape. 
## energyCost ::: ammount of enegry spent by each agent each timestep.
## radius ::: Search Neighbouhood (in Chebyshev distance)
## verbose ::: If set to TRUE shows a progress bar
## plot ::: If se to TRUE plots population size and agent location in the resourcescape




main<-function(nAgents=50,energyCost=25,maxEnergy=100,resourceGrowthRate=25,
               nSteps=100,dimX=30,dimY=30,
               plot=TRUE,verbose=TRUE,radius=1)
    {
        population=rep(0,nSteps) #placeholder for recording population size 
        resource=matrix(round(runif(dimX*dimY,0,maxEnergy)),nrow=dimX,ncol=dimY) #initialise resourceScape
        maxResource=resource #maximum possible resource value per cell

        ##initialise agents as a data.frame:
        agents=data.frame(energy=rep(maxEnergy/2,nAgents),
            x=ceiling(runif(nAgents,0,dimX)),y=ceiling(runif(nAgents,0,dimX)))

        ##Start of the actual simulation#
        if(verbose==TRUE){pb <- txtProgressBar(min = 1, max = nSteps, style = 3)}

        for (t in 1:nSteps)
            {

                ##STEP 1: Agents Move to the cell with highest energy within its neighbourhood#              
                for (a in 1:nrow(agents))
                            {
    
                                agents[a,2:3]=neighbourhood(xcor=agents$x[a],ycor=agents$y[a],
                                                  xLimit=c(1,dimX),yLimit=c(1,dimY),
                                                  resourceMatrix=resource,radius=radius)                             
                            }
                
                ##STEP 2: Agents Collect Energy from current cell, after randomising order of exectution      
                
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
                if(any(agents$energy==maxEnergy))
                    {
                        parents=which(agents$energy==maxEnergy)
                        agents$energy[parents]=maxEnergy/2
                        offspring=agents[parents,]
                        offspring$energy = offspring$energy + energyCost #add extra energy to keep the offspring energy value after next step
                        agents<-rbind(agents,offspring)
                    }

                ##STEP 3: Spend Energy#
                agents$energy=agents$energy-energyCost

                ##STEP 4: Death#
                if(any(agents$energy<=0))
                    {
                      death=which(agents$energy<=0)
                      if(length(death)==nrow(agents))
                            {
                                agents=agents[-death,]
                                print("extinction!")
                                return(population)
                            }
                       agents=agents[-death,]                     
                    }

                ##STEP 5: Resource Growth#
                                       
                resource=resource+resourceGrowthRate
                index=which((resource-maxResource)>0,arr.ind=TRUE)
                resource[index]=maxResource[index]

                ##Record Population Size:
                population[t]=nrow(agents)
                
                ##Optional Plot Function#
                if(plot==TRUE)
                    {
                        par(mfrow=c(1,2))
                        plot(1:t,population[1:t],type="l",xlab="time",ylab="population",
                             main=paste("Avg.Energy=",round(mean(agents$energy),2)))
                        image(x=1:dimX,y=1:dimY,z=resource,main=paste("Avg.Resource=",round(mean(resource),2)),
                              zlim=c(0,maxEnergy),xlab="x",ylab="y")
                        points(x=agents$y,y=agents$x,pch=20,cex=2)
                    }

                if(verbose==TRUE){setTxtProgressBar(pb, t)}
            }
        if(verbose==TRUE){close(pb)}
        return(population)
    }



###utility functions###
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
        if(length(goto)>1){goto=sample(goto,size=1)}
        finaladdress=address[goto,]        
        return(finaladdress)
    }
}

randomNeighbour<-function(xcor,ycor,xLimit,yLimit,radius)
    {
        step=-radius:radius
        xcor1=xcor+step
        ycor1=ycor+step
        address=expand.grid(x=xcor1,y=ycor1)

        if(sum((address$x<xLimit[1]|address$x>xLimit[2]),na.rm=TRUE)>0){address[which(address$x<xLimit[1]|address$x>xLimit[2]),]=NA}
        if(sum((address$y<yLimit[1]|address$y>yLimit[2]),na.rm=TRUE)>0){address[which(address$y<yLimit[1]|address$y>yLimit[2]),]=NA}

        address[which(address[,1]==xcor&address[,2]==ycor),]=NA
        finaladdress=address[sample(which(!is.na(address[,1])),size=1),]
        return(finaladdress)
    }
