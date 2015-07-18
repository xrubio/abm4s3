#
# Copyright (c) 2015 - Xavier Rubio-Campillo 
# This file is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version
#
# The source code is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#   
# You should have received a copy of the GNU General Public 
# License along with this library.  If not, see <http://www.gnu.org/licenses/>.

#!/usr/bin/python3

import decision, random

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
        params.nAgents = random.randint(1,200)
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
    radiusValues = range(1,31)
    numRuns = repetitions*len(radiusValues)
    numRun = 0
    for i in radiusValues:
        for j in range(repetitions):
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
    equifinality()

if __name__ == "__main__":
    main()

