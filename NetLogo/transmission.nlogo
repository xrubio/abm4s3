;; define variables
globals [nTraits traitRange moveDistance colorRange simpson stopnow] ;; number of traits an agent can possess, number of values that a trait can have,
  ;; rate at which agents reproduce (an agent will die for each new one hatched), distance an agent moves each time step, 256/traitRange for setting
  ;; agent colors, Simpson divesity index, stop simulation flag

breed [agents agent] ;; plural and singular form of agent referent
agents-own [traits] ;; information that can be transmitted. Stored as list with "nTraits" items, where each place can take up to "traitRange" values (0-traitRange)

to setup
  ;; set up global values, agents, patches, and world map matrices
  
  clear-all
  set stopnow false
  set nTraits 3 ;; number of traits possessed by each agent. Stored as places in the "traits" list for each agent. This model is hard-coded for 3 traits
  set traitRange 5 ;; number of values that a trait can take
  set moveDistance 1 ;; distance an agent can move each time step
  set colorRange round (256 / traitRange) ;; 256 grey shades / traitRange - used to set agent color
  if timeSteps = "" [set timeSteps 0] ;; change empty max tick limit entry into an integer
  if randomAgents [set nAgents random 450 + 50]
  create_agents
  reset-ticks ;; start time steps ("ticks") at 0
end

to create_agents
  ;; procedure to instantiate forager agents and agent variables
  
  create-agents nAgents [ ;; create a number of agents determined by user-selectable variable nAgents (slider in GUI)
    set traits (list random 5 random 5 random 5)  
    setxy random-xcor random-ycor ;; place agents randomly in gridded landscape (on patches)
    set-color ;; set initial color of agent based on trait values
    set shape "circle" ;; set default agent shape
    set size 0.3 ;; set default agent size
  ]
end

to set-color
  ;; set color of agent based on trait values
  
  let r (item 0 traits + 1) * colorRange
  let b (item 1 traits + 1) * colorRange
  let g (item 2 traits + 1) * colorRange
  set color rgb r b g
end

to go
  ask agents [
    move ;; call move procedure for each agent
    
    ;; agent chooses which kind of transmission to carry out (all agents currently use same transmission process selected by user).
    if transmissionType = "vertical" [vertical] ;; call vertical transmission procedure, where information is transmitted only to offspring
    if transmissionType = "unbiased" [unbiased] ;; call horizanal transmission procedure, where information it transmitted to another agent encountered while moving
    if transmissionType = "prestige" [prestige] ;; call horizanal transmission procedure, where probability of information transmission is determined by value in prestige trait (trait 0) of another agent encountered while moving
    if transmissionType = "conformist" [conformist] ;; call horizanal transmission procedure, where information transmission is determined by the popularity of a trait value among agents within "interactionRadius" of calling agent
  ]
  tick ;; increment time step counter
  update-plots
  if timeSteps > 0 and ticks >= timeSteps [summarize]  ;; do summary statistics and stop simulation if time steps exceed timeSteps value
  if stopnow [stop]
end

to vertical
  ;; transmission of information to offspring with chance of innovation or copying error
  
  if random-float 1 <= replacementRate [ ;; check to see if agent can reproduce
    hatch 1 [ ;; clone agent (has same traits initially)
      innovate ;; call innovation/copy error procedure
      set-color ;; call procedure to set agent color to indicate new cultural knowledge if there is innovation/copy error
      ask one-of agents [die] ;; kill off one agent to keep population stable
      ]    
    ]
end

to unbiased
  ;; horizontal transmission of information between two agents who encounter each other 
  ;;   within an area defined by "interactionRadius" (set by user) when moving in gridded landscape, 
  ;;   with chance of innovation or copying error
  
  let place random 3 ;; randomly choose trait to change
  
  let partner one-of other agents in-radius interactionRadius ;; randomly select an agent within "interactionRadius" to copy from
  if partner != nobody [ ;; check to see if a partner for copying has been identified
    set traits replace-item place traits [item place traits] of partner ;; learn new information copied from partner
    ]
  
  innovate ;; call innovation/copy error procedure
  set-color ;; call procedure to set agent color to indicate new cultural knowledge
end

to prestige
  ;; horizontal transmission of information between two agents who encounter each other 
  ;;   within an area defined by "interactionRadius" (set by user) when moving in gridded landscape, 
  ;;   with chance of innovation or copying error. Probability of copying from another agent determined by
  ;;   value of "prestige" trait (item 0 of trait list)

  let place random 3 ;; randomly choose trait to change (note that this may not be the trait conferring prestige).

  let partner one-of other agents in-radius interactionRadius ;; randomly select an agent within "interactionRadius" to copy from
  let prestigePlace 0 ;; set prestige trait as item 0 in "traits" (trait list)
  if partner != nobody [ ;; check to see if a partner for copying has been identified
    let prestigeValue [item prestigePlace traits] of partner ;; evaluate prestige of partner
    if random-float 1 <= (prestigeValue + 1) / traitRange [ ;; prestige of partner determins probability that value will be copied
      set traits replace-item place traits [item place traits] of partner ;; learn new information copied from partner
    ]
  ]

  innovate ;; call innovation/copy error procedure
  set-color ;; call procedure to set agent color to indicate new cultural knowledge
end

to conformist
  ;; horizontal transmission of information where the trait value copied is the most common one of other agents 
  ;;   within an area defined by "interactionRadius" (set by user) when moving in gridded landscape.
  ;;   For best results, interactionRadius should be set to a value > 1. But results may vary as interactionRadius changes

  let information "" ;; information to be copied or innovated
  let place random 3 ;; randomly choose trait to change

  let partners other agents in-radius interactionRadius ;; all other agents within interactionRadius
  if partners != nobody [ ;; check to be sure that there are partners to copy from
    ;type "partners = " print count partners
    let popularity [] ;; list to hold numbers of agents with each value for the trait selected
    foreach n-values traitRange [?]  [ 
      ;; generate popularity list such that the position in the list indicates the trait value 
      ;;   and the value of the list item the number of neighboring agents with that trait value
      set popularity lput (count partners with [item place traits = ?]) popularity ;; add agent count to popularity list
      ]
    
    let mostPopular [] ;; list of the most popular trait values (can contain more than one entry if there are ties)
    let index 0 ;; position in popularity list, indicating trait value
    foreach popularity [
      if ? = max popularity [
        set mostPopular lput index mostPopular ;; add trait value to list of most popular trait values
        ]
      set index index + 1 ;; increment popularity list position counter
      ]
    set traits replace-item place traits one-of mostPopular ;; choose one of the most popular trait values and learn it
    ]
  
  innovate ;; call innovation/copy error procedure
  set-color ;; call procedure to set agent color to indicate new cultural knowledge
end

to innovate
  ;; innovation or copying error
  
  if random-float 1 <= innovationRate  [ ;; check to see if there is an innovation/copying error
    let place random 3 ;; randomly choose trait to change
    set traits replace-item place traits (random 5) ;; assign a random value to trait 
  ] 
end

to move
  ;; simple movement routine
  
  rt random 360
  if patch-ahead moveDistance = nobody [ rt random 360 lt random 360] ;; avoids boundaries of gridded landscape
  fd moveDistance
end

to summarize
  ;; calculate Simpson diversity index at end of simulation before stopping
  
  let divSum 0
  let tList remove-duplicates [traits] of agents ; create list of trait configurations 
  
  ; Simpson Index
  foreach tList [
    set divSum divSum + (count agents with [traits = ?] / count agents) ^ 2
    ]
  set simpson 1 - divSum

  set stopnow true ; stop simulation
end
@#$#@#$#@
GRAPHICS-WINDOW
475
55
785
386
-1
-1
30.0
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
9
0
9
0
0
1
ticks
30.0

CHOOSER
5
90
143
135
transmissionType
transmissionType
"vertical" "unbiased" "prestige" "conformist"
0

SLIDER
5
10
145
43
nAgents
nAgents
1
100
287
1
1
NIL
HORIZONTAL

SLIDER
155
75
295
108
innovationRate
innovationRate
0
1
0.01
.01
1
NIL
HORIZONTAL

BUTTON
390
10
452
43
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
390
50
453
83
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
5
185
455
310
Trait 0 Frequencies
trait value
agents
0.0
5.0
0.0
10.0
true
false
"" ""
PENS
"trait-0" 1.0 1 -2674135 true "" "histogram [item 0 traits] of agents"

SLIDER
5
140
145
173
interactionRadius
interactionRadius
1
20
1
1
1
NIL
HORIZONTAL

PLOT
5
315
455
440
Trait 1 Frequency
trait value
agents
0.0
5.0
0.0
10.0
true
false
"" ""
PENS
"trait-1" 1.0 1 -13840069 true "" "histogram [item 1 traits] of agents"

PLOT
5
445
455
570
Trait 2 Frequency
trait value
agents
0.0
5.0
0.0
10.0
true
false
"" ""
PENS
"trait-2" 1.0 1 -13345367 true "" "histogram [item 2 traits] of agents"

INPUTBOX
155
115
295
175
timeSteps
1000
1
0
Number

SWITCH
5
50
145
83
randomAgents
randomAgents
0
1
-1000

MONITOR
365
135
455
180
total agents
count agents
0
1
11

INPUTBOX
155
10
295
70
replacementRate
0.1
1
0
Number

BUTTON
390
90
453
123
Step
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

This models exemplifies information transmission and learning in small-scale societies. It simulates vertical transmission (from parent to offspring), as well as three kinds of horizontal transmission: unbiased, prestige-based, and conformist. It is one of two models that accompany the paper:

Rubio-Campillo, Xavier, Mark Altaweel, C. Michael Barton, and Enrico R. Crema (in press) Understanding Small-Scale Societies with Agent-Based Models: Theoretical Examples of Cultural Transmission and Decision-Making. Ecology and Society

For the paper, both models have been coded in four popular platforms: NetLogo (here), Repast, R, and Python. 

## HOW IT WORKS

Each agent posesses 3 different traits (numbered as traits 0, 1, and 2), each of which can have 5 possible values (0-4). For vertical transmission, a parent will transmit all of its trait configurations (i.e., the value for each of the 3 traits) to its offspring. There is a possibility that the offspring will change one of these values. The probability that this will happen is set by the user at the beginning of the simulation with the 'innovationRate' slider.

For each of the 3 types of horizontal transmission, an agent identifies a 'teacher' agent within a neighborhood set by the user with the 'interactionRadius' slider at the beginning of the simulation. The agent will then copy the value of 1 trait from the selected teacher. The innovationRate is the probability that, instead of copying from a teacher, an agent will randomly select a new value for the trait in question. 

For unbiased transmission, an agent will select a teacher randomly from the other agents within its interaction radius. The agent will then randomly select a trait and copy its value from the teacher.

For conformist, an agent will select a teacher within its interation radius that has the most common value for one (randomly selected) trait. The agent will then copy that value for its corresonding trait.
 
For prestige, an agent will select as a teacher an agent within the interation radius who has the highest value for trait 0. The agent will then copy the value of a randomly selected trait from the teacher. 

The 'replacement rate' entry field allows the user to set a probability that 1 agent will die and a new one born (a randomly selected agent will clone itself) each model tick. An agent's traits convey no selective value or penalty. They do not affect the chance of death or reproduction. The population of agents remains stable at the initial value set by the user.

## HOW TO USE IT

Set the parameters described above. Press the 'Setup' button to initialize the environment and place the agents in the environment. Press the 'Run' button, Pressing the 'Step' button will advance the model one tick. The timeSteps entry field allows the user to stop the model running after a predetermined number of ticks. Setting this field to 0 allows the model to run indefinitely, until the user presses 'Go' again. 

## THINGS TO NOTICE

The colors of the agents indicate their different trait values. When all agents have the same color, they have the same trait values. The bar graphs show the number of agents who posess each value for each trait. 


## THINGS TO TRY

Which transmission modes and other parameters better maintain variability in traits and which rapidly lead to all agents posessing identical traits?

## EXTENDING THE MODEL



## NETLOGO FEATURES



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
  <experiment name="transmission_experiment1" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count agents</metric>
    <metric>simpson</metric>
    <enumeratedValueSet variable="replacementRate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmissionType">
      <value value="&quot;vertical&quot;"/>
      <value value="&quot;encounter&quot;"/>
      <value value="&quot;prestige&quot;"/>
      <value value="&quot;conformist&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="innovationRate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saveOutput">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomAgents">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timeSteps">
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interactionRadius">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="transmission_experiment2" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count agents</metric>
    <metric>simpson</metric>
    <enumeratedValueSet variable="replacementRate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmissionType">
      <value value="&quot;vertical&quot;"/>
      <value value="&quot;encounter&quot;"/>
      <value value="&quot;prestige&quot;"/>
      <value value="&quot;conformist&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="innovationRate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saveOutput">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomAgents">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timeSteps">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interactionRadius">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="transmission_experiment3" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count agents</metric>
    <metric>simpson</metric>
    <enumeratedValueSet variable="replacementRate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmissionType">
      <value value="&quot;vertical&quot;"/>
      <value value="&quot;encounter&quot;"/>
      <value value="&quot;prestige&quot;"/>
      <value value="&quot;conformist&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="innovationRate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saveOutput">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomAgents">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timeSteps">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interactionRadius">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="transmission_experiment4" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count agents</metric>
    <metric>simpson</metric>
    <enumeratedValueSet variable="replacementRate">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmissionType">
      <value value="&quot;vertical&quot;"/>
      <value value="&quot;unbiased&quot;"/>
      <value value="&quot;prestige&quot;"/>
      <value value="&quot;conformist&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="innovationRate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="saveOutput">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomAgents">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timeSteps">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interactionRadius">
      <value value="1"/>
    </enumeratedValueSet>
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
