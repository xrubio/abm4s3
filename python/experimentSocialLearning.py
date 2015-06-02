#!/usr/bin/python3

import socialLearning, random

def singleRun():  
    params = socialLearning.Params()
    params.transmissionType = 'prestige'
    params.nAgents = 30
    params.nSteps = 100
    params.output = 'output.csv'
    params.oneFile = False 
    socialLearning.run(params)

def experiment():
    numRuns = 100
    transmissionTypeSweep = ['vertical','encounter','prestige','conformist']
    
    params = socialLearning.Params()
    params.xDim = 10
    params.yDim = 10
    params.replacementRate = 0.1
    params.moveDistance = 1.0
    params.interactionRadius = 1.0
    params.innovationRate = 0.01
    params.nTraits = 3
    params.nTraitRange = 5
    params.prestigeIndex = 1

    params.nSteps = 1000
    params.storeAllSteps = True 
    params.oneFile = False 
    totalRuns = 0

    # perform numRuns of each type, randomly sampling from nAgents 10 to 500
    for i in transmissionTypeSweep:
        for j in range(0, numRuns):
            print('run:',totalRuns+1,'of:',numRuns*len(transmissionTypeSweep))
            params.numRun = totalRuns
            params.transmissionType = i
            params.nAgents = random.randint(50,500)
            params.output = 'output_tr_'+str(params.numRun)+'.csv'
            totalRuns += 1
            socialLearning.run(params)

def main():
    singleRun()

if __name__ == "__main__":
    main()

