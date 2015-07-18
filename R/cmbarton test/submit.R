load("readyRun.RData")
initialPop=c(1,5,10,15,20)
experiment=c(0,1,2)
runs=1:100
store=expand.grid(initialPop=initialPop,runs=runs,experiment=experiment)

library(utils)
library(foreach)
library(doParallel)
registerDoParallel(cores=6)


pb <- txtProgressBar(min = 1, max = nrow(store), style=3)
Results=foreach(i=1:nrow(store),.combine=c) %dopar%
{
    setTxtProgressBar(pb, i)
    testFun(nAgents=store$initialPop[i],experiment=store$experiment[i])
}
close(pb)
store$res=Results
save.image("finishedRun.RData")



######
library(ggplot2)

data0=subset(store,experiment==0)
ggplot(data0, aes(initialPop, res)) +
geom_point(position = "jitter") +
ggtitle("Test 0 (with reproduction and resource growth)") +
xlab("Initial nAgents") +
ylab("Final nAgents") +
ylim(0,30)
dev.print(device=png,file="./test0_EC_v2.png",width=500,height=450)


data1=subset(store,experiment==1)
data1=subset(store,experiment==1)
ggplot(data1, aes(initialPop, res)) +
geom_point(position = "jitter") +
ggtitle("Test 1 (no reproduction with resource growth)") +
xlab("Initial nAgents") +
ylab("Final nAgents") +
ylim(0,30)
dev.print(device=png,file="./test1_EC_v2.png",width=500,height=450)

data2=subset(store,experiment==2)
data2=subset(store,experiment==2)
ggplot(data2, aes(initialPop, res)) +
geom_point(position = "jitter") +
ggtitle("Test 2 (no reproduction with no resource growth)") +
xlab("Initial nAgents") +
ylab("Time to Extinction")
dev.print(device=png,file="./test2_EC_v2.png",width=500,height=450)
