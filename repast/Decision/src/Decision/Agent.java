package Decision;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import repast.simphony.context.Context;
import repast.simphony.engine.environment.RunEnvironment;
import repast.simphony.engine.environment.RunState;
import repast.simphony.engine.schedule.ScheduleParameters;
import repast.simphony.engine.schedule.ScheduledMethod;
import repast.simphony.parameter.Parameters;
import repast.simphony.query.space.grid.GridCell;
import repast.simphony.query.space.grid.GridCellNgh;
import repast.simphony.query.space.grid.GridWithin;
import repast.simphony.random.RandomHelper;
import repast.simphony.space.continuous.ContinuousSpace;
import repast.simphony.space.grid.Grid;
import repast.simphony.space.grid.GridPoint;
import simphony.util.messages.MessageCenter;

public class Agent {

	/**The type of decision scenario*/
	String decisionType="";
	
	/**Max energy value*/
	double maxEnergy=0;
	
	/**The energy cost of action*/
	double energyCost=0;
	
	/**The continuous space an agent operates in*/
	public ContinuousSpace<Object> space;
	
	/**The grid in which the agent operates in*/
	public Grid<Object> grid;

	/**The energy of the agent*/
	private Double energy;

	/**Boolean for cases of where memory is used in a scenario*/
	public boolean memory;
	
	/**The mental map of a space the agent has*/
	double map[][];

	/**Cell's resource growth rate*/
	private Double cellResoureGrowthRate;
	
	/**The search radius for resources an agent wants*/
	private int searchRadius;
	
	/**The cell in which the agent will consume from*/
	private Cell consumeCell;
	
	/**Tick timestamp of when the agent was born*/
	private double tickBorn=0;
	
	/**
	 * 
	 */
	public Agent(){
		
	}
	
	/**
	 * The constructor for the agent 
	 * 
	 * @param space the space an agent operates in
	 * @param grid the grid an agent operates in
	 */
	public Agent(ContinuousSpace<Object> space, Grid<Object>grid){
		Parameters p = RunEnvironment.getInstance().getParameters();
		this.grid=grid;
		
		//here the agent's attributes are being initialized
		this.maxEnergy = (Double)p.getValue("maxEnergy");
		this.energyCost = (Double)p.getValue("energyCost");
		this.cellResoureGrowthRate=(Double)p.getValue("resourceGrowthRate");
		this.energy=this.maxEnergy*0.5;
		this.decisionType =(String)p.getString("decisionType");
		this.memory=(Boolean)p.getBoolean("memory");
		this.searchRadius=(Integer)p.getInteger("searchRadius");
		
		this.space=space;
		
		int xDim = (Integer)p.getValue("xDim");
		int yDim = (Integer)p.getValue("yDim");
		map=new double[xDim][yDim];
	}
	
	/**
	 * For cases where the agent is greedy, the agent moves to a neighbourhood based on a greedy desire.
	 */
	public void greedyMove(){
	//	 List<GridCell<Object>> neighbourhood=getNeighbourhood();
		List<Cell> neighbourhood=getNeighbourhood();
		
		 Cell cc=null;
		 double energyCell=-10d;
		 
		 //iterate over the grid cells and find the one that fits the greedy desire
		for(Cell gc: neighbourhood){
			
					if(!memory){
						 if(gc.resource>energyCell){
							energyCell=gc.resource;
							 cc=gc;
						 }
						 if(gc.resource==energyCell){
							 int ri=RandomHelper.nextIntFromTo(0, 1);
							 if(ri==0)
								 cc=gc;
						 }
					 }
					 else{
						 if(map[gc.x][gc.y]>energyCell){
							 energyCell=map[gc.x][gc.y];
							 cc=gc;
						 }
					 }		 
	//			 }
	//		 }
		 }
		 
		//this will be the greedy cell to consume
		this.consumeCell=cc;
	}
	
	/**
	 * The general step method that selects which scenario and which cell to go to. 
	 */
	 @ScheduledMethod(start = 1, interval = 2,priority = ScheduleParameters.FIRST_PRIORITY,shuffle=false)
	 public void step(){
	 
		 //here the conditionals control the options for which simulation type you want
		 if(!memory){
			 if(decisionType.equalsIgnoreCase("greedy")){
				 greedyMove();
			 }
		 
			 if(decisionType.equalsIgnoreCase("probabilistic")){
				 probabilityMove();
			 }
		 }
		 else{ 
			 memoryMechanism();
			 if(decisionType.equalsIgnoreCase("greedy")){
				 greedyMove();
			 }
		 
			 if(decisionType.equalsIgnoreCase("probabilistic")){
				 probabilityMove();
			 }
		 }
	 }
	 
	 /**
	  * Chebshev distance calculation between two cells
	  * @param c1 cell 1
	  * @param c2 cell 2
	  * @return the distance calculation
	  */
	 public double chebyshevDistance(Cell c1, Cell c2){
		 double max = Math.abs(c1.x-c2.x);     
	     double abs = Math.abs(c1.y-c2.y);
	     
	     if(abs > max) 
	          max = abs;
	        
	      return max; 
	 }
	 
	 /**
	  * The second step of the model, where the agent will go to a chosen cell, consume energy,
	  * reproduce, or die.
	  */
	 @ScheduledMethod(start = 2, interval = 2,priority = ScheduleParameters.FIRST_PRIORITY)
	 public void stepTwo(){	
		 
		 if(this.tickBorn==RunEnvironment.getInstance().getCurrentSchedule().getTickCount())
			 return;
		 
		 grid.moveTo(this, consumeCell.x,consumeCell.y);
		 space.moveTo(this, consumeCell.x,consumeCell.y);
		
		 consume(consumeCell);
				 
		 if(this.maxEnergy==this.energy)
			 reproduce();
		 
		 spendEnergy();
		 if(this.energy<=0){
			 RunState.getSafeMasterContext().remove(this);
		 }
	 }
	 
	 /**
	  * A move based on probability of moving to an area based on resources in the area.
	  */
	 public void probabilityMove(){
		List<Cell> neighbourhood=getNeighbourhood();
		 
		
		Map<Cell,Double>resourcesC=new HashMap<Cell,Double>();
		
		//iterate over the cells and move to the one based on a probability, which is based on its resources
		 double energyCell=0;
		 for(Cell c: neighbourhood){
			
			 resourcesC.put(c, c.resource);
					 
			if(!memory)
				energyCell+=c.resource;
			else
				energyCell+=map[c.x][c.y];		  
		 }
		 
		 Cell chosen=currentCell();
	
		 double r=RandomHelper.nextDouble();
		 Iterator<Cell>ci = resourcesC.keySet().iterator();
		 double oldRange=0;
		 while(ci.hasNext()){
			 Cell c = ci.next();
			 
			 double enG=0;
			 if(!memory)
				 enG=c.resource;
			 else
				 enG=map[c.x][c.y];
			 
			 if((oldRange/energyCell)<r && r<((oldRange+enG)/energyCell)){
				 chosen=c;
				 break;
			 }
			 else{ 
				oldRange+=enG;
			 }
				
		 }
		 this.consumeCell=chosen;
	//	 consume(chosen);
	//	 grid.moveTo(this, chosen.x,chosen.y);
	//	 space.moveTo(this, chosen.x,chosen.y);
	 }
	 
	 /**
	  * Here the agent finds the current cell it is in.
	  * @return the current cell
	  */
	 public Cell currentCell(){
		 GridPoint pt = grid.getLocation(this);
		 Iterator<Object>is=grid.getObjectsAt(pt.getX(),pt.getY()).iterator();
		 
		 Cell cc=null;
		 while(is.hasNext()){
			 Object oo = is.next();
			 if(oo instanceof Cell){
				 cc=(Cell)oo;
				 break;
			 }
		 }
		 return cc;
	 }
	 
	 /**
	  * Method to control how an agent remembers an area visited for resources in order to select it again.
	  */
	 public void memoryMechanism(){ 
		 List<Cell> neighbourhood=getNeighbourhood();
		 for(Cell gc: neighbourhood){
			 
			map[gc.x][gc.y]=(gc.resource+map[gc.x][gc.y])/2.0;

		}				 
	 }
	 
	 /**
	  * Method for consuming energy.
	  * @param c
	  */
	 public void consume(Cell c){	
		 //this simply removes energy from the cell and then gives that energy to the agent
		 double energyDiff=this.maxEnergy-this.energy;
		 
		 double addEnergy=0;
		 if(c.resource>(this.maxEnergy-this.energy))
			 addEnergy=energyDiff;
		 
		 else
			 addEnergy=c.resource;
		 
		 c.resource=c.resource-addEnergy;
		 this.energy=Math.min(this.energy+addEnergy,this.maxEnergy);
	 }
	 
	 /**
	  * Simple reproduction based on using energy.
	  * The agent uses 1/2 their energy to reproduce and give the new agent 1/2 their energy.
	  */
	 public void reproduce(){
		
		 //here another agent is created then half the energy is given to that agent and the other half is kept by the agent reproducing
		 Agent agent = new Agent(this.space,this.grid);
		 agent.tickBorn=RunEnvironment.getInstance().getCurrentSchedule().getTickCount();
		 this.energy=this.maxEnergy*0.5;
		 Context context =RunState.getSafeMasterContext();
		 context.add(agent);
		
		 //the agent goes to the parent's location
		 space.moveTo(agent,space.getLocation(this).getX(),space.getLocation(this).getY());
		 grid.moveTo(agent, grid.getLocation(this).getX(),grid.getLocation(this).getY());
	 }
	 
	 /**
	  * Energy spent at each tick.
	  */
	 public void spendEnergy(){
		 this.energy=this.energy-this.energyCost;
	 }
	 
	 /**
	  * The neighbourhood surrounding the cells of choice
	  * @return a list of the neighbourhood
	  */
	 	public List<Cell> getNeighbourhood(){
	 		
			GridPoint pt = grid.getLocation(this);
			Cell c = currentCell();
			
			Context context = RunState.getInstance().getMasterContext();
			Iterator<Cell> ii = context.getObjects(Cell.class).iterator();
			
			List<Cell> cells = new ArrayList<Cell>();
			while(ii.hasNext()){
				Cell cc = ii.next();
				
				if(chebyshevDistance(c,cc)<=(double)this.searchRadius  && !cells.contains(cc)){
					cells.add(cc);
				}
			}
			
	//		space.getObjectAt(location)
			
			return cells;
		}


	public Double getEnergy() {
		return energy;
	}


	public void setEnergy(Double energy) {
		this.energy = energy;
	}

	public double getEnergyCost() {
		return energyCost;
	}

	public void setEnergyCost(double energyCost) {
		this.energyCost = energyCost;
	}

	public Double getCellResoureGrowthRate() {
		return cellResoureGrowthRate;
	}

	public void setCellResoureGrowthRate(Double cellResoureGrowthRate) {
		this.cellResoureGrowthRate = cellResoureGrowthRate;
	}

	public int getSearchRadius() {
		return searchRadius;
	}

	public void setSearchRadius(int searchRadius) {
		this.searchRadius = searchRadius;
	}
	
 }



