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

import random, math

def enum(**enums):
    """ converts a sequence of values to an C++ style enum """
    return type('Enum', (), enums)

DecisionType = enum(eGreedy=0, eProb=1)    

class Position:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def distance(self, pos):
        diffX = self.x-pos.x
        diffY = self.y-pos.y
        return math.sqrt(diffX*diffX+diffY*diffY)

    def __str__(self):
        return(str(self.x)+'/'+str(self.y))

class BaseAgent:
    # static attributes
    # energy threshold for reproduction
    maxEnergy = 0
    # map of resources
    resources = None 
    # amount of energy spent by step
    energyCost = 1
    radius = 1

    agents = None
    newAgents = None

    def __init__(self, pos, initEnergy):
        self.pos = pos
        self.energy = int(initEnergy)

    def move(self):
        candidates = list()
        maxValue = 0
        for i in range(self.pos.x-self.radius, self.pos.x+1+self.radius):
            for j in range(self.pos.y-self.radius, self.pos.y+1+self.radius):
                candidate = Position(i,j)
                # if not inside boundaries skip
                if not self.resources.isInside(candidate):
                    continue
                # greedy agent
                newValue = self.resources.getValue(candidate)
                if newValue<maxValue:
                    continue
                elif newValue==maxValue:
                    candidates.append(candidate)
                else:
                    maxValue = newValue
                    candidates = []
                    candidates.append(candidate)
        random.shuffle(candidates)
        self.pos = candidates[0]

    def collectEnergy(self):     
        energyInCell = self.resources.getValue(self.pos)
        collected = int(min(energyInCell, self.maxEnergy - self.energy))
        self.resources.setValue(self.pos, self.resources.getValue(self.pos) - collected)
        self.energy += collected

    def clone(self):
        # energy must be maxEnergy for cloning
        if self.energy < self.maxEnergy:
            return
        child = BaseAgent(self.pos, int(self.energy/2))
        self.energy -= child.energy
        BaseAgent.newAgents.append(child)

    def spendEnergy(self):
        self.energy -= self.energyCost

    def __str__(self):
        content = 'agent pos:'+str(self.pos)+' energy:'+str(self.energy)
        return(content)

class Map:
    def __init__(self, xDim, yDim):
        self.xDim = xDim
        self.yDim = yDim
        self.values = list()

        for i in range(0,self.xDim):
            newRow = list()
            for j in range(0,self.yDim):
                newRow.append(None)
            self.values.append(list(newRow))

    def clone(self):                
        newMap = Map(self.xDim, self.yDim)
        for i in range(0,self.xDim):
            for j in range(0,self.yDim):
                newMap.values[i][j] = self.values[i][j]
        return newMap           

    def getValue(self, pos):
        return self.values[pos.x][pos.y]

    def setValue(self, pos, value):
        self.values[pos.x][pos.y] = value    

    def isInside(self, pos):
        if pos.x <0 or pos.y < 0:
            return False
        if pos.x>=self.xDim or pos.y>=self.yDim:
            return False
        return True

    def __str__(self):
       output = ''
       for i in range(0,self.xDim):
            for j in range(0,self.yDim):
                output += '['+str(i)+','+str(j)+']='+str(self.values[i][j])+' '
            output += '\n'
       return output

class ResourcesMap(Map):
    def __init__(self, xDim, yDim, maxEnergy, resourceGrowthRate):
        Map.__init__(self, xDim, yDim)
        self.growthRate = resourceGrowthRate     
    
        # create both maps (current and max)
        self.maxValues = list()
        # initialize map of resources
        self.fillValues(maxEnergy)


    def fillValues(self, maxEnergy):
        # create max values
        for i in range(0,self.xDim):   
            newRow = list()
            for j in range(0,self.yDim):
                newRow.append(random.randint(0, maxEnergy))
            self.maxValues.append(newRow)
        # copy
        for i in range(0,self.xDim):
            for j in range(0,self.yDim):
                self.values[i][j] = self.maxValues[i][j]
    
    def step(self):
        for i in range(0,self.xDim):
            for j in range(0,self.yDim):
                # already max capacity, skip
                if self.values[i][j] == self.maxValues[i][j]:
                    continue
                self.values[i][j] = min(self.values[i][j]+self.growthRate, self.maxValues[i][j])

    def __str__(self):
       output = ''
       for i in range(0,self.xDim):
            for j in range(0,self.yDim):
                output += '['+str(i)+','+str(j)+']='+str(self.values[i][j])+'/'+str(self.maxValues[i][j])+' '
            output += '\n'
       return output


class Params:
    def __init__(self):
        self.numRun = 0
        self.output = 'output_dmp.csv'
        self.oneFile = False
        ### agents config
        # base config
        self.nAgents = 1
        self.nSteps = 1000

        # additional params
        # max energy an agent or a cell can accumulate
        self.maxEnergy = 100
        # energy they consume each cycle
        self.energyCost = 9

        ### environment config
        # dimensions of world
        self.xDim = 30
        self.yDim = 30
        # radius of collection
        self.radius = 1
        # regeneration for each cell for each time step
        self.resourceGrowthRate = 2

def run(params):
    resources = ResourcesMap(params.xDim, params.yDim, params.maxEnergy, params.resourceGrowthRate)

    BaseAgent.resources = resources
    BaseAgent.maxEnergy = params.maxEnergy
    BaseAgent.energyCost = params.energyCost
    BaseAgent.radius = params.radius

    BaseAgent.agents = list() 
    BaseAgent.newAgents = list() 

    for i in range(0, params.nAgents):
        newPos = Position(random.randint(0,params.xDim-1), random.randint(0,params.yDim-1))
        newAgent = BaseAgent(newPos, params.maxEnergy/2)
        BaseAgent.agents.append(newAgent)

    if params.oneFile==False or params.numRun==0:
        # storage            
        output = open(params.output,'w')
        # header
        output.write('run;radius;step;pop\n')
    else:
        output = open(params.output,'a')

    for i in range(0,params.nSteps):
        random.shuffle(BaseAgent.agents)  
        for agent in BaseAgent.agents:
            agent.move()

        for agent in BaseAgent.agents:
            agent.collectEnergy()
            agent.clone()
        # old agents consume
        for agent in BaseAgent.agents:
            agent.spendEnergy()
        BaseAgent.agents += BaseAgent.newAgents
       
        # remove agents without energy
        BaseAgent.agents[:] = [agent for agent in BaseAgent.agents if agent.energy>0]
        BaseAgent.newAgents = list()
        resources.step()
        output.write(str(params.numRun)+';'+str(params.radius)+';'+str(i)+';'+str(len(BaseAgent.agents))+'\n')
    output.close()      

