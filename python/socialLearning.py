#!/usr/bin/python3

import random, math

def enum(**enums):
    """ converts a sequence of values to an C++ style enum """
    return type('Enum', (), enums)

TransmissionType = enum(eVertical = 0, eEncounter = 1, ePrestige = 2, eConformist = 3)

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

    # class params 
    innovationRate = 0.01
    moveDistance = 1.0
    xDim = 10
    yDim = 10
    replacementRate = 0.1

    # list of all agents
    agents = None
    # list of new agents (added to the simulation in the step after they are created)
    newAgents = None

    def __init__(self, pos, nTraits, nTraitRange):
        self.nTraitRange = nTraitRange
        self.traits = list()
        self.createTraits(nTraits)
        self.pos = pos

    def createTraits( self, nTraits):
        for i in range(0, nTraits):
            self.traits.append(random.randint(0,self.nTraitRange-1))

    def step(self):
        self.move()
    
    def reproduce(self):
        newAgent = BaseAgent(self.pos, len(self.traits), self.nTraitRange)
        # vertical transmission
        for i,value in enumerate(self.traits):
            newAgent.traits[i] = value
        # innovation is divided by replacement rate to enable comparison with the other models
        if random.random()<(self.innovationRate/self.replacementRate):
            innovationIndex = random.randint(0,len(newAgent.traits)-1)
            newAgent.traits[innovationIndex] = random.randint(0, self.nTraitRange-1)
        return newAgent

    def correctPos(self, newPos):
        if newPos.x<0 or newPos.x>=self.xDim:
            return False
        if newPos.y<0 or newPos.y>=self.yDim:
            return False
        return True

    def getRandomPos(self):
        direction = random.randint(0,360)
        radians = math.radians(direction)
        newPos = Position(self.pos.x, self.pos.y)
        newPos.x += self.moveDistance*math.cos(radians)
        newPos.y += self.moveDistance*math.sin(radians)
        return newPos

    def move(self):
        newPos = self.getRandomPos()
        while not self.correctPos(newPos):
            newPos = self.getRandomPos()
        self.pos = newPos

    def __str__(self):
        content = 'agent\n\tpos:'+str(self.pos)+'\n\ttraits- '
        for index,value in enumerate(self.traits):
            content += str(index) + ':'+str(value)+' '
        content += '\n'
        return(content)

class EncounterAgent(BaseAgent):
    interactionRadius = 1.0

    def __init__(self, pos, nTraits, nTraitRange):
        BaseAgent.__init__(self, pos, nTraits, nTraitRange)

    def getNeighbors(self):
        candidates = list()
        for agent in self.agents:
            if agent.pos.distance(self.pos) >= self.interactionRadius:
                continue
            candidates.append(agent) 
        return candidates

    def transmission(self, candidate):
        traitToCopy = random.randint(0,len(self.traits)-1)
        # innovation
        if random.random()<self.innovationRate:
            self.traits[traitToCopy] = random.randint(0, self.nTraitRange-1)
        # transmission
        else:
            self.traits[traitToCopy] = candidate.traits[traitToCopy]

    def selectNeighbour(self):
        candidates = self.getNeighbors()
        if len(candidates)==0:
            return None
        random.shuffle(candidates)
        return candidates[0]

    def step(self):
        self.move()
        candidate = self.selectNeighbour()
        # no agents inside interactionRadius
        if candidate == None:
            return
        self.transmission(candidate)

class PrestigeAgent(EncounterAgent):
    prestigeIndex = 0

    def __init__(self, pos, nTraits, nTraitRange):
        EncounterAgent.__init__(self, pos, nTraits, nTraitRange)
  
    def step(self):
        self.move()
        neighbors = self.getNeighbors()
        prestigeValues = list()
        for index,neighbor in enumerate(neighbors):
            for i in range(0,neighbor.traits[self.prestigeIndex]+1):
                prestigeValues.append(index)
        candidate = neighbors[random.sample(prestigeValues,1)[0]]
        self.transmission(candidate)

class ConformistAgent(EncounterAgent):
    def __init__(self, pos, nTraits, nTraitRange):
        EncounterAgent.__init__(self, pos, nTraits, nTraitRange)
   
    def step(self):
        self.move()
        analysedIndex = random.randint(0,len(self.traits)-1)

        if random.random()<self.innovationRate:
            self.traits[analysedIndex] = random.randint(0, self.nTraitRange-1)
            return

        # create a list of frequencies = 0
        possibleValues = [0] * self.nTraitRange
        neighbors = self.getNeighbors()
        # for each neighbor, add 1 to the count of the frequency of the value in analysedIndex
        for agent in neighbors:
            possibleValues[agent.traits[analysedIndex]] += 1
        # look for the max frequency
        candidateValues = list()
        maxFrequency = 0
        for index,value in enumerate(possibleValues):
            if value > maxFrequency:
                candidateValues = list()
                maxFrequency = value
                candidateValues.append(index)
            elif value == maxFrequency:
                candidateValues.append(index)
        # choose randomly one of the highest frequency values of the trait and copy it
        random.shuffle(candidateValues)
        self.traits[analysedIndex] = candidateValues[0]

def computeFrequencies():
    traits = list()
    frequencies = list()

    for agent in BaseAgent.agents:
        genotype = 0
        base = 1
        for i in reversed(range(0,len(agent.traits))):
            genotype += base*agent.traits[i]
            base *= 10
        try:
            position = traits.index(genotype)
        except ValueError:
            position = len(traits)
            traits.append(genotype)
            frequencies.append(0)
        frequencies[position] += 1
    return frequencies

def storeDiversity(output, params, step):
    frequencies = computeFrequencies()

    value = 0
    total = sum(frequencies)

    for frequency in frequencies:
        value += pow((frequency/total),2)
    value = 1.0 - value
    output.write(str(params.numRun)+';'+str(params.nAgents)+';'+params.transmissionType+';')
    if params.storeAllSteps:
        output.write(str(step)+';')
    output.write(str(value)+'\n')

class Params:
    def __init__(self):
        # base config
        self.numRun = 0
        self.oneFile = False
        self.output = 'output_tr.csv'
        self.nAgents = 100
        self.nSteps = 1000
        self.storeAllSteps = True
        self.xDim = 10
        self.yDim = 10

        ## agent config
        # transmission types (vertical, encounter, prestige, conformist)
        self.transmissionType = 'vertical'
        # number of traits
        self.nTraits = 3
        # number of variations of each trait
        self.nTraitRange = 5

        self.moveDistance = 1.0
        self.interactionRadius = 1.0
        # percentage of agents replaced every time step
        self.replacementRate = 0.1        
        # prob of changing a trait
        self.innovationRate = 0.01

def run(params):
    
    # basic init of parameters
    BaseAgent.innovationRate = params.innovationRate
    BaseAgent.moveDistance = params.moveDistance
    BaseAgent.xDim = params.xDim
    BaseAgent.yDim = params.yDim
    BaseAgent.replacementRate = params.replacementRate
    EncounterAgent.interactionRadius = params.interactionRadius

    transmission = TransmissionType.eVertical
    if params.transmissionType=='encounter':
        transmission = TransmissionType.eEncounter
    elif params.transmissionType=='prestige':
        transmission = TransmissionType.ePrestige
    elif params.transmissionType=='conformist':
        transmission = TransmissionType.eConformist
 
    # create the list of agents        
    BaseAgent.agents = list() 

    for i in range(0, params.nAgents):
        newPos = Position(random.randint(0,params.xDim-1), random.randint(0,params.yDim-1))
        if transmission == TransmissionType.eVertical:
            BaseAgent.agents.append(BaseAgent(newPos, params.nTraits, params.nTraitRange))
        elif transmission == TransmissionType.eEncounter:
            BaseAgent.agents.append(EncounterAgent(newPos, params.nTraits, params.nTraitRange))
        elif transmission == TransmissionType.ePrestige:
            BaseAgent.agents.append(PrestigeAgent(newPos, params.nTraits, params.nTraitRange))
        elif transmission == TransmissionType.eConformist:
            BaseAgent.agents.append(ConformistAgent(newPos, params.nTraits, params.nTraitRange))

    # init storage
    if params.oneFile==False or params.numRun==0:   
        # storage            
        output = open(params.output,'w')
        if params.storeAllSteps:
            # header
            output.write('run;nAgents;transmissionType;step;simpson\n')
        else:
            output.write('run;nAgents;transmissionType;simpson\n')
    else:
        output = open(params.output,'a')

    # execution         
    for i in range(0,params.nSteps):
        # random execution of the agents
        random.shuffle(BaseAgent.agents)
        for agent in BaseAgent.agents:
            agent.step()

        # vertical transmission is the only one with replacements
        if transmission==TransmissionType.eVertical:
             # replacements
            replacementNum = int(len(BaseAgent.agents)*BaseAgent.replacementRate)
            # add as many agents as replacementNum
            BaseAgent.newAgents = list()
            for rep in range(0,replacementNum):
                nextParent = random.choice(BaseAgent.agents)
                child = nextParent.reproduce()
                BaseAgent.newAgents.append(child)

            # shuffle and remove as many agents as replacementNum
            random.shuffle(BaseAgent.agents)
            # death
            for rep in range(0,replacementNum):
                BaseAgent.agents.pop()
            # add new agents
            BaseAgent.agents += BaseAgent.newAgents

        # if all steps must be stored or it is the last step then store
        if params.storeAllSteps==True or i==(params.nSteps-1):
            # store simpsons index
            storeDiversity(output, params, i)
    output.close()

