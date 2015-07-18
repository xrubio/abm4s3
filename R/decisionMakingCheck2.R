


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



#Define Parameters
energyCost=25;maxEnergy=100;resourceGrowthRate=25;nSteps=100;dimX=10;dimY=10

#Read Raster
resource=as.matrix(read.csv("~/Desktop/raster.csv",sep=";",header=F))
colnames(resource)=NULL
maxResource=resource #maximum possible resource value per cell
agents=data.frame(energy=rep(maxEnergy/2,1),
    x=1,y=1)


cat("\n",file="~/Desktop/traceR.log",append=FALSE)

#Execute Simulation
for (t in 1:nSteps)
            {
cat(paste("step:",t-1,sep=""),file="~/Desktop/traceR.log",append=TRUE) #log time-step
cat("\n",file="~/Desktop/traceR.log",append=TRUE)
cat("Agents Before Movement:",file="~/Desktop/traceR.log",append=TRUE)
cat("\n",file="~/Desktop/traceR.log",append=TRUE)

for (a in 1:nrow(agents))
    {
        cat(paste(agents[a,2:3]-1,collapse="/"),file="~/Desktop/traceR.log",append=TRUE)
        cat(paste("(",agents[a,1],")",sep=""),file="~/Desktop/traceR.log",append=TRUE)
        cat("\n",file="~/Desktop/traceR.log",append=TRUE)
    }

                #STEP 1: Agents Move to the cell with highest energy within its neighbourhood#              
                for (a in 1:nrow(agents))
                            {
                                agents[a,2:3]=neighbourhood(xcor=agents$x[a],ycor=agents$y[a],
                                          xLimit=c(1,dimX),yLimit=c(1,dimY),
                                          resourceMatrix=resource,radius=radius)
                            }

cat("Agents After Movement:",file="~/Desktop/traceR.log",append=TRUE)
cat("\n",file="~/Desktop/traceR.log",append=TRUE)

for (a in 1:nrow(agents))
    {
        cat(paste(agents[a,2:3]-1,collapse="/"),file="~/Desktop/traceR.log",append=TRUE)
        cat(paste("(",agents[a,1],")",sep=""),file="~/Desktop/traceR.log",append=TRUE)
        cat("\n",file="~/Desktop/traceR.log",append=TRUE)
    }

                #STEP 2: Agents Collect Energy from current cell, after randomising order of exectution      
                
              #  newOrder=sample(1:nrow(agents)) 
              #  agents=agents[newOrder,]  #shuffle agent order
                
                  for (a in 1:nrow(agents))
                            {              
                                        #agents consume
                                collection = maxEnergy-agents$energy[a] #max possible collection
                                energyInCell = resource[agents$x[a],agents$y[a]] #available ammount of energy
                                collected = min(energyInCell, maxEnergy - agents$energy[a])[1]
                                resource[agents$x[a],agents$y[a]]=resource[agents$x[a],agents$y[a]]-collected
                                agents$energy[a]=agents$energy[a]+collected
                            }

cat("Agents After Collection:",file="~/Desktop/traceR.log",append=TRUE)
cat("\n",file="~/Desktop/traceR.log",append=TRUE)

for (a in 1:nrow(agents))
    {
        cat(paste(agents[a,2:3]-1,collapse="/"),file="~/Desktop/traceR.log",append=TRUE)
        cat(paste("(",agents[a,1],")",sep=""),file="~/Desktop/traceR.log",append=TRUE)
        cat("\n",file="~/Desktop/traceR.log",append=TRUE)
    }




                #STEP 3: Agents make a copy of themselves if their energy is equal to maxEnergy
                if(any(agents$energy==maxEnergy))
                    {
                        parents=which(agents$energy==maxEnergy)
                        agents$energy[parents]=maxEnergy/2
                        agents<-rbind(agents,agents[parents,])
                    }

cat("Agents After Reproduction:",file="~/Desktop/traceR.log",append=TRUE)
cat("\n",file="~/Desktop/traceR.log",append=TRUE)

for (a in 1:nrow(agents))
    {
        cat(paste(agents[a,2:3]-1,collapse="/"),file="~/Desktop/traceR.log",append=TRUE)
        cat(paste("(",agents[a,1],")",sep=""),file="~/Desktop/traceR.log",append=TRUE)
        cat("\n",file="~/Desktop/traceR.log",append=TRUE)
    }



                #STEP 3: Spend Energy#
                agents$energy=agents$energy-energyCost

cat("Agents After Energy Expenditure:",file="~/Desktop/traceR.log",append=TRUE)
cat("\n",file="~/Desktop/traceR.log",append=TRUE)

for (a in 1:nrow(agents))
    {
        cat(paste(agents[a,2:3]-1,collapse="/"),file="~/Desktop/traceR.log",append=TRUE)
        cat(paste("(",agents[a,1],")",sep=""),file="~/Desktop/traceR.log",append=TRUE)
        cat("\n",file="~/Desktop/traceR.log",append=TRUE)
    }


                #STEP 4: Death#
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

cat("Agents After Death:",file="~/Desktop/traceR.log",append=TRUE)
cat("\n",file="~/Desktop/traceR.log",append=TRUE)

for (a in 1:nrow(agents))
    {
        cat(paste(agents[a,2:3]-1,collapse="/"),file="~/Desktop/traceR.log",append=TRUE)
        cat(paste("(",agents[a,1],")",sep=""),file="~/Desktop/traceR.log",append=TRUE)
        cat("\n",file="~/Desktop/traceR.log",append=TRUE)
    }


cat("Resource Map before Growth:",file="~/Desktop/traceR.log",append=TRUE)
cat("\n",file="~/Desktop/traceR.log",append=TRUE)

for (i in 1:10)
    {
        for (j in 1:10)
            {
                cat(paste("[",i-1,",",j-1,"]=",resource[i,j],"/",maxResource[i,j]," ",sep=""),file="~/Desktop/traceR.log",append=TRUE)
            }
        cat("\n",file="~/Desktop/traceR.log",append=TRUE)

    }
        cat("\n",file="~/Desktop/traceR.log",append=TRUE)



                #STEP 5: Resource Growth#
                                       
                resource=resource+resourceGrowthRate
                index=which((resource-maxResource)>0,arr.ind=TRUE)
                resource[index]=maxResource[index]



                
            }

