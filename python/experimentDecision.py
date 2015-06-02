#!/usr/bin/python3

import decision, random
from scipy import arange

def equilibrium():
    params = decision.Params()
    params.nSteps = 5000
    params.radius = 1
    params.nAgents = 30
    params.output = 'fig1.csv'
    params.maxEnergy = 10
    params.energyCost = 2
    params.resourceGrowthRate = 2
    params.xDim = 30
    params.yDim = 30
    decision.run(params)

def equifinality():    
    repetitions = 10
    params = decision.Params()
    params.nSteps = 150
    params.radius = 1
    params.output = 'fig2a.csv'
    params.maxEnergy = 10
    params.energyCost = 3
    params.resourceGrowthRate = 3
    params.xDim = 30
    params.yDim = 30
    params.oneFile = True

    for i in range(repetitions):
        print('run:',i,'from:',repetitions)
        params.numRun = i
        params.nAgents = random.randint(1,500)
        decision.run(params)

def multifinality():    
    repetitions = 3
    params = decision.Params()
    params.nSteps = 300
    params.radius = 3
    params.output = 'fig2b.csv'
    params.maxEnergy = 50
    params.energyCost = 10
    params.resourceGrowthRate = 10
    params.nAgents = 50
    params.xDim = 30
    params.yDim = 30
    params.oneFile = True

    for i in range(repetitions):
        print('run:',i,'from:',repetitions)
        params.numRun = i
        decision.run(params)

def singleRun():
    params = decision.Params()
    params.nSteps = 100
    params.nAgents = 10
    params.output = 'output.csv'
    params.maxEnergy = 10
    params.energyCost = 1
    params.resourceGrowthRate = 1 
    params.xDim = 10
    params.yDim = 10
    decision.run(params)

def exploreRadius():
    repetitions = 1000
    radiusValues = arange(1,31)
    numRuns = repetitions*len(radiusValues)
    numRun = 0
    for i in radiusValues:
        for j in arange(repetitions):
            params = decision.Params()
            params.oneFile = False 
            params.nSteps = 5001
            params.nAgents = 50
            params.maxEnergy = 100
            params.energyCost = 25
            params.resourceGrowthRate = 25
            params.xDim = 30
            params.yDim = 30
            params.numRun = numRun
            params.radius = i
            params.output = 'output_dec_'+str(numRun).zfill(5)+'.csv'
            print('run:',numRun+1,'of:',numRuns,'radius:',params.radius) 
            decision.run(params)
            numRun += 1

def main():
    singleRun()

if __name__ == "__main__":
    main()

