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

import transmission, random

def singleRun():  
    params = transmission.Params()
    params.transmissionType = 'prestige'
    params.nAgents = 30
    params.nSteps = 100
    params.output = 'output.csv'
    params.oneFile = False 
    transmission.run(params)

def experiment():
    numRuns = 100
    transmissionTypeSweep = ['vertical','encounter','prestige','conformist']
    
    params = transmission.Params()
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
            transmission.run(params)

def main():
    singleRun()

if __name__ == "__main__":
    main()

