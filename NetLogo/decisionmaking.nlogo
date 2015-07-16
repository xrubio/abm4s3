extensions [csv] ;; load matrix extension to use for agent memtal maps

;; define variables
globals [outFile worldMap] ;; name and path of output csv file, generic mental map used by all agents
breed [agents agent] ;; plural and singular form of agent referent
agents-own [energy] ;; current energy level of an agent, mental map matrix of agent
patches-own [resource maxResource] ;; current resources of a patch, maximum resources that can exist on a patch


to setup
  ;; set up global values, agents, patches, and world map matrices
  clear-all
  if timeSteps = "" [set timeSteps 0] ; change empty max tick limit entry into an integer
  setup-patches ;; call procedure to instantiate patches and patch variables of gridded landscape
  create_agents ;; cal procedure to instantiate forager agents and agent variables
  reset-ticks ;; start time steps ("ticks") at 0
end

to setup-patches
  ;; procedure to instantiate patches and patch variables of gridded landscape
  ask patches [
    set maxResource random 100  ;; maximum potential resource on each patch
    set resource maxResource    ;; initialize each patch with maximum potential resource
    set pcolor scale-color green resource 100 0 ;; set patch color to a shade of green to indicate resource amount (dark is more)
    ]
end

to create_agents
  ;; procedure to instantiate forager agents and agent variables
  create-agents nAgents [ ;; create a number of agents determined by user-selectable variable nAgents (slider in GUI)
    set energy maxEnergy / 2 ;; start each agent with 1/2 of the maximum possible energy that agents can possess
    setxy random-xcor random-ycor ;; place agents randomly in gridded landscape (on patches)
    set color scale-color red energy 0 maxEnergy ;; set agent color to a shade of red to indicate amount of energy (dark is more)
    set shape "circle" ;; set default agent shape
    set size 1 ;; set default agent size
    ]
end

to go
  ;; procedure that cycles simulation through time steps. Loops endlessly unless stopped by user or if ticks surpass value of timeSteps variable 
  ask agents [
    ;; behavior of each agent during each time step
    seek-resources
    ]
  ask agents [
    consume ;; consume resources
    if energy >= maxEnergy [reproduce] ;; if energy level of agent reaches maxEnergy value (set by user), call "reproduce" procedure
    set energy energy - energyCost ;; energy cost for living and moving; decrease agent stored energy by energyCost value (set by user) each time step
    if energy <= 0 [die] ;; if energy level of agent falls to 0, agent dies
    set color scale-color red energy 0 maxEnergy ;; reset agent color to indicate new energy level after foraging and living/moving
    ]
  ask patches [regrow] ;; call "regrow" procedure to increment resources
  tick
  if (timeSteps > 0 and ticks = timeSteps) or count agents = 0 [stop] ;; stop simulation if time steps exceed timeSteps value
end

to seek-resources 
  ;; Find neighborhood patch with most resources, move there, and consume resources
  let allNeighbors search-patches  
  let best max [resource] of allNeighbors ;; identify neighborhood patch with most resources
  move-to one-of allNeighbors with [resource = best] ;; move to patch with most resources
end

to consume
  ;; agent consumes resource and resource value added to stored energy of agent. Agent can only consume up to maxEnergy level
  let need maxEnergy - energy ;; determine how much energy can be consumed by agent
  ifelse need < [resource] of patch-here
  [set energy energy + need ;; if energy needs of agent are less than available resouce, consume up to maxEnergy level
    ask patch-here [set resource resource - need]] ;; reduce patch resource level by amount consumed
  [set energy energy + [resource] of patch-here ;; if energy needs are greater than or equal to amount of resources on patch, consume all resouce on patch and increase agent energy by that amount
    ask patch-here [set resource 0]]
end

to regrow
  ;; regrow patch resource if not being consumed by agent
  if resource < maxResource [
    set resource resource + resourceGrowthRate ;; increment patch resource by "resourceGrowthRate" (set by User) up to maxResource level for that patch
    if resource > maxResource [set resource maxResource]
    set pcolor scale-color green resource 100 0 ;; reset color to indicate resource amount on patch
    ]
end

to reproduce
  ;; agent reproduces by cloning if it reaches maxEnergy
  let originalEnergy energy
    hatch 1 [ ;; agent clones self
      ;move-to one-of search-patches; offspring moves to another patch
      set energy originalEnergy / 2 ;; agent offsprint/clone gets half of original agent energy
    ]
    set energy originalEnergy / 2 ;; reduce agent energy to half original amount (because other half went to offspring)
end

to-report search-patches 
  ;; compute Chebechev square for neghboring patches to search for resoures
  let xmax [pxcor] of patch-here + searchRadius
  let xmin [pxcor] of patch-here - searchRadius
  let ymax [pycor] of patch-here + searchRadius
  let ymin [pycor] of patch-here - searchRadius
  let allNeighbors patches with [pxcor <= xmax and pxcor >= xmin and pycor <= ymax and pycor >= ymin]
  
  ;; Chebechev distance computed for compatibility with other model implementations.
  ;; An easier method in NetLogo is to use circular radius. For example:
  ;;      let allNeighbors (patch-set patches in-radius searchRadius patch-here)
  
  report allNeighbors
end
@#$#@#$#@
GRAPHICS-WINDOW
470
25
975
551
-1
-1
16.5
1
10
1
1
1
0
1
1
1
0
29
0
29
0
0
1
ticks
30.0

SLIDER
10
25
155
58
nAgents
nAgents
1
200
50
1
1
NIL
HORIZONTAL

BUTTON
320
25
382
58
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
395
25
458
58
run
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
10
345
450
505
Average, Maximum, & Minimum Agent Energy
time
energy
0.0
4.0
0.0
10.0
true
false
"" ""
PENS
"avg-energy" 1.0 0 -13345367 true "" "if count agents > 0 [plot mean [energy] of agents]"
"pen-1" 1.0 0 -2064490 true "" "if count agents > 0 [plot max [energy] of agents]"
"pen-2" 1.0 0 -2064490 true "" "if count agents > 0 [plot min [energy] of agents]"

INPUTBOX
165
105
310
165
timeSteps
5000
1
0
Number

SLIDER
10
65
155
98
maxEnergy
maxEnergy
1
200
100
1
1
NIL
HORIZONTAL

SLIDER
10
105
155
138
energyCost
energyCost
1
30
25
1
1
NIL
HORIZONTAL

SLIDER
165
65
310
98
resourceGrowthRate
resourceGrowthRate
1
30
25
1
1
NIL
HORIZONTAL

PLOT
10
175
450
335
Active Agents
time
agents
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count agents"

SLIDER
165
25
310
58
searchRadius
searchRadius
1
50
5
1
1
NIL
HORIZONTAL

MONITOR
320
120
450
165
active agents
count agents
0
1
11

BUTTON
395
65
458
98
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This models exemplifies simple decision-making in searching for and acquiring resources in small scale, hunter-gather societies. It is one of two models that accompany the paper:

Rubio-Campillo, Xavier, Mark Altaweel, C. Michael Barton, and Enrico R. Crema (in press) Understanding Small-Scale Societies with Agent-Based Models: Theoretical Examples of Cultural Transmission and Decision-Making. Ecology and Society

For the paper, both models have been coded in four popular platforms: NetLogo (here), Repast, R, and Python. 

## HOW IT WORKS

This is a simple model where agents search for the most productive resource patch within a neighborhood, whose size can be set by the user with the 'searchRadius' slider. Agents then move to that patch and attempt to consume the resources on the patch.

INITIALIZATION

An environment is created in which the maximum possible amount of resources that can grow on each patch is a random number between 0 and 100. Whenever resources are consumed from a patch, they regrow at a rate for each model tick determined by the user ('resourceGrowthRate' slider), up to the maximum allowed for that patch.

A number of agents set by the user ('nAgents' slider) are initialized with 50% of their maximum possible energy, set by the user with the 'maxEnergy' slider. Living and seeking resources cost each agent an amount of energy each model tick that is set by the user with the 'energyCost' slider.

MODELING RUNNING

Each model tick, agents identify the most productive patch in their neighborhood, move to that patch, and attempt to consume resources from the patch. An agent will attempt to consume all the energy it 'needs'. Energy need is the difference between an agent's current energy level and the maxEnergy value set by the user at initialization. If the amount of resources on a patch is less than the energy need, an agent will consume all resouces on that patch. 
 
Importantly, all agents identify the most productive patch and then move to it before any agent consumes resources. After all agents move to selected patches, then agents consume resources. The order in which agents consume resources is randomized each model tick. Thus, if more than one agent occupies the same patch, the agent that consumes first gets the most resources. 

After consuming resources, if an agent has reached its maxEnergy level, it will reproduce by cloning itself. The original agent and the offspring will each receive half of the original agent's energy. For example, if maxEnergy is set to 100, an agent that consumes sufficient resources to reach an energy level of 100 will reproduce. The agent and its offspring will each have energy levels of 50 after reproduction. 

After attempting to reproduce, successfully or not, each agent will then lose energy equal to energyCost. If energyCost=25 and maxEnergy=100, an agent that has reproduced will end up with 100/2 = 50 - 25 = 25 final energy points. An offspring agent does not move, consume, or incur an energyCost at birth.

If the energy level of an agent declines to 0, the agent dies. 

## HOW TO USE IT

Set the parameters described above. Press the 'Setup' button to initialize the environment and place the agents in the environment. Press the 'Go' button, Pressing the 'Step' button will advance the model one tick. The timeSteps entry field allows the user to stop the model running after a predetermined number of ticks. Setting this field to 0 allows the model to run indefinitely, until the user presses 'Go' again. 

## THINGS TO NOTICE

The number of agents will often climb rapidly, decline rapidly, then stablize at a 'carrying capacity' number. 

## THINGS TO TRY

Watch the relationship between the number of agents that survive (carrying capacity) and the size of the neighborhood defined by searchRadius.

## EXTENDING THE MODEL

The searchRadius defines a Chebychev 'square' neighborhood. Try changing this to a circular neighborhood. See comments in the search-patches procedure.

As coded, all agents seek the best patch and move to it. Then all agents consume, reproduce, spend energy, and possibly die. This causes agents to potentially compete for resources on the same patch.

Move the "seek-resources" call so that each agent in turn seeks the best patch, consumes, reproduces, spends energy, and possibly dies. In this way, each agent will assessessment of the best patch will be determined in part by other agents' behavior.

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

As part of the package that contains this published model, there are versions of the same model coded in Repast, Python, and R. There is also a related model of information transmission, also coded in NetLogo, Repast, Python, and R.


## CREDITS AND REFERENCES

(c) C. Michael Barton, Arizona State University
This model is licenced under the GNU General Public License v. 3
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Decision-making experiment 1" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>count agents</metric>
    <metric>mean [energy] of agents</metric>
    <enumeratedValueSet variable="maxEnergy">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outputInterval">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="resourceGrowthRate">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="memory">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decisionType">
      <value value="&quot;greedy&quot;"/>
      <value value="&quot;probabalistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomAgents">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saveOutput">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyCost">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timeSteps">
      <value value="1000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="decision_experiment2_ECtest" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>count agents</metric>
    <metric>mean [energy] of agents</metric>
    <enumeratedValueSet variable="nAgents">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyCost">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxEnergy">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="resourceGrowthRate">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timeSteps">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="memory">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decisionType">
      <value value="&quot;greedy&quot;"/>
      <value value="&quot;probabalistic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomAgents">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saveOutput">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Decision-making_experiment4" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>count agents</metric>
    <metric>mean [energy] of agents</metric>
    <enumeratedValueSet variable="maxEnergy">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="resourceGrowthRate">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyCost">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timeSteps">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nAgents">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="searchRadius">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="decision-making_experiment6.1" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>count agents</metric>
    <metric>mean [energy] of agents</metric>
    <enumeratedValueSet variable="maxEnergy">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="resourceGrowthRate">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyCost">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timeSteps">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nAgents">
      <value value="10"/>
      <value value="50"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="searchRadius">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="decisionmaking_experiment6" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>count agents</metric>
    <metric>mean [energy] of agents</metric>
    <enumeratedValueSet variable="maxEnergy">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="resourceGrowthRate">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyCost">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timeSteps">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nAgents">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="searchRadius">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="decisionmaking_experiment6plus" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>count agents</metric>
    <metric>mean [energy] of agents</metric>
    <enumeratedValueSet variable="maxEnergy">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="resourceGrowthRate">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyCost">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timeSteps">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nAgents">
      <value value="30"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="searchRadius">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="decisionmaking_experiment_forpaper" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>count agents</metric>
    <metric>mean [energy] of agents</metric>
    <enumeratedValueSet variable="maxEnergy">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="resourceGrowthRate">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyCost">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timeSteps">
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nAgents">
      <value value="50"/>
    </enumeratedValueSet>
    <steppedValueSet variable="searchRadius" first="1" step="1" last="30"/>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
1
@#$#@#$#@
