###############################################################
## ~Cultural Transmission Model~
## by enrico.crema@gmail.com                                       
##     
## Parameters:  
## nAgents ::: Number of Agents
## transmissionType :::  Transmission mode one between {"vertical","encounter","prestige","conformist"}
## nTraits ::: Number of slots in the vector of cultural traits
## nTraitRange ::: Range of possible integer values that can be stored
## xDim ::: dimension of the world (x-coordinate)
## yDim ::: dimension of the world (y-coordinate)
## replacementRate ::: rate of population replacement (only for "vertical" transmission mode)
## timeSteps ::: number of simulation time-steps
## innovationRate ::: rate of innovation
## interactionRadius ::: interaction distance (euclidean distance)
## moveDistance ::: movement distance (euclidean distance)
## verbose ::: If set to TRUE shows a progress bar
## plot ::: If set to TRUE plots the population level diversity index,agents location, and traits (using rgb values)


main<-function(nAgents=100,xDim=10,yDim=10,interactionRadius=1,moveDistance=1,
               timeSteps=5000,nTraits=3,transmissionType=c("vertical","encounter","prestige","conformist"),
               nTraitRange=c(0,1,2,3,4),prestigeIndex=1,replacementRate=0.1,
               innovationRate=0.01,plotSim=TRUE,verbose=TRUE)
    {
        require(vegan)
        ##define a list where the agents traits are stored
        rawTraitsList=vector("list",length=timeSteps)
        ##define a vector where the diversity values of each timestep is stored
        diversitySequence=numeric(length=timeSteps)
        
        ##Initialise Agents as data.frame:
        ##Random Traits
        Agents=as.data.frame(matrix(sample(nTraitRange,size=nTraits*nAgents,replace=TRUE),nrow=nAgents,ncol=nTraits))
        ##Random Location
        Agents$x=runif(nAgents,0,xDim)
        Agents$y=runif(nAgents,0,yDim)

        if(verbose==TRUE){pb <- txtProgressBar(min = 1, max = timeSteps, style = 3)}

        for (t in 1:timeSteps)
            {
                ##move agents
                Agents[,c(nTraits+1,nTraits+2)]=t(apply(Agents[,c(nTraits+1,nTraits+2)],1,
                          function(x,y,xDim,yDim)
                              {
                                  return(move(coordinate=x[c(1,2)],moveDistance=y,xDim=xDim,yDim=yDim))
                              },y=moveDistance,xDim=xDim,yDim=yDim))

                ##Social Learning

                ############Vertical Transmission###########
                if (transmissionType=="vertical")
                    {
                        reproduce=which(runif(nrow(Agents))<replacementRate) #index of reproducing agents
                        deathNumber=length(reproduce) #compute number of deaths, equal to the number of new agents
                        dead=sample(1:nrow(Agents),size=deathNumber) #randomly select the index value of dying agents
                        if (length(reproduce)>0) #if any change
                            {   
                                newAgents=Agents[reproduce,] #store offspring
                                
                                        ##innovation:
                                innovationIndex=which(runif(nrow(newAgents))<innovationRate) #index of innovators
                                if (length(innovationIndex)>0) #if innovation happens
                                    {
                                        newAgents[innovationIndex,sample(1:nTraits,size=1)]=sample(nTraitRange,size=1)
                                    }
                            }
                                        ##Update Agents:
                        if (length(dead)>0){Agents=Agents[-dead,]} #kill agents
                        if (length(reproduce)>0){Agents=rbind(Agents,newAgents)} #add new agents     
                    }


                ############Horrizontal Transmission###########
                if (transmissionType=="encounter"|transmissionType=="prestige")
                    {
                        Agents<-Agents[sample(1:nrow(Agents)),] #randomise order of agents  
                        coord<-Agents[,-c(1:nTraits)]
                        distMat=as.matrix(dist(coord)) #compute euclidean distance matrix
                        diag(distMat)=NA #Ensure Self if excluded
                        targetAgentIndex<-apply(distMat,1,neighbourChooser,radius=interactionRadius) #select random neighbour
                        if(transmissionType=="prestige") 
                            {
                                transmissionProbability=(Agents[targetAgentIndex,prestigeIndex]+1)/(max(nTraitRange)+1) #retrieve transmission probability
                                targetAgentIndex[which(runif(1)>transmissionProbability)]=NA 
                            }
                        
                        for (a in 1:nrow(Agents))
                            {
                                copyLocus=sample(1:nTraits,size=1)
                                if(!is.na(targetAgentIndex[a]))
                                    {
                                        Agents[a,copyLocus]=Agents[targetAgentIndex[a],copyLocus]
                                        if(runif(1)<innovationRate){Agents[a,copyLocus]=sample(1:nTraits,size=1)}  #innovation       
                                    }
                            }
                    }


                ############Conformist Transmission###########

                if (transmissionType=="conformist")

                    {
                      Agents<-Agents[sample(1:nrow(Agents)),] #randomise order of agents  
                      coord<-Agents[,-c(1:nTraits)]
                      distMat=as.matrix(dist(coord))
                      diag(distMat)=NA #Ensure Self if excluded

                      neighbours<-apply(distMat,1,function(x,y){return(as.numeric(x<y))},y=interactionRadius)
                       for (a in 1:nrow(Agents))
                           {
                              copyLocus=sample(1:nTraits,size=1)
                              if(any(neighbours[a,]>0,na.rm=TRUE))
                                  {
                                      targetTraits=table(Agents[which(neighbours[a,]==1),copyLocus])
                                      if (length(targetTraits)==1){Agents[a,copyLocus]=as.numeric(names(targetTraits))}
                                      if (length(targetTraits)>1)
                                          {
                                              tmp=as.numeric(names(targetTraits)[which(targetTraits==max(targetTraits))])
                                              if(length(tmp)==1){Agents[a,copyLocus]=tmp}
                                              if(length(tmp)>1){Agents[a,copyLocus]=sample(tmp,1)}
                                          }
                                      if(runif(1)<innovationRate){Agents[a,copyLocus]=sample(1:nTraits,size=1)}   #innovation      
                                  }
                           }




                    }
      
                rownames(Agents)=1:nrow(Agents)
                
                ##store output
                diversitySequence[t]=diversity(table(as.character(apply(Agents[,1:3],1,paste,collapse=""))),"simpson")
                ##plot function

                if(plotSim==TRUE)
                    {
                        par(mfrow=c(1,2))
                        plot(1,1,xlim=c(0,xDim),ylim=c(0,yDim),xlab="x",ylab="y",type="n",main=t)
                        colors=(Agents[,1:nTraits]+1)*1/(max(nTraitRange)+1)
                        colors=apply(colors,1,function(x){return(rgb(red=x[1],green=x[2],blue=x[3]))})
                        points(Agents$x,Agents$y,col=colors,pch=20,cex=2)
                        plot(1:t,diversitySequence[1:t],type="l",xlab="time",ylab="diversity",xlim=c(0,timeSteps),ylim=c(0,1))
                    }

                if(verbose==TRUE){setTxtProgressBar(pb, t)}
                
                
            }

             if(verbose==TRUE){close(pb)}
        output=diversitySequence
        return(output)
    }



#####################
# Utility Functions #
#####################


# Count number of cases defined in "variants" within the vector "x":
instances<-function(x,variants)
{
        x=c(x,variants)
        res<-table(x)-1
        return(res)
}

# Randomly move the agents in any direction with distance "moveDistance": 
move<-function(coordinate,moveDistance=1,xDim,yDim)
    {
        x0=coordinate[1]
        y0=coordinate[2]
        x1=-1
        y1=-1
        while((x1<0|x1>xDim)|(y1<0|y1>yDim))
            {
                angl=runif(1,min=0,max=2*pi)
                x1=moveDistance*cos(angl)+x0
                y1=moveDistance*sin(angl)+y0
            }
        return(c(x1,y1))
    }

# Choose one random agents within a neighbourhood of distance "radius".
# x is the distance vector to the other agents

neighbourChooser<-function(x,radius)
    {
        finalIndex=NA
        if (any(x<radius,na.rm=TRUE))
            {
                index=which(x<radius)
                if(length(index)>1)
                    {finalIndex=sample(as.numeric(index),size=1)}
                if(length(index)==1)
                    {finalIndex=index}
            }
        return(finalIndex)
    }
