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
import repast.simphony.random.RandomHelper;
import repast.simphony.space.continuous.ContinuousSpace;
import repast.simphony.space.grid.Grid;
import repast.simphony.space.grid.GridPoint;

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
		this.energy=this.maxEnergy/2.0;
		this.decisionType =(String)p.getString("decisionType");
		this.memory=(Boolean)p.getBoolean("memory");
		
		this.space=space;
		
		int xDim = (Integer)p.getValue("xDim");
		int yDim = (Integer)p.getValue("yDim");
		map=new double[xDim][yDim];
	}
	
	/**
	 * For cases where the agent is greedy, the agent moves to a neighbourhood based on a greedy desire.
	 */
	public void greedyMove(){
		 List<GridCell<Object>> neighbourhood=getNeighbourhood();
		 
		 Cell cc=currentCell();
		 double energyCell=cc.resource;
		 
		 //iterate over the grid cells and find the one that fits the greedy desire
		for(GridCell gc: neighbourhood){
			
			 Iterator<Object> gi = gc.items().iterator();
			 while(gi.hasNext()){
				 Object o = gi.next();
				 
				 if(o instanceof Cell){
					 Cell c = (Cell)o;
					 if(!memory){
						 if(c.resource>energyCell){
							energyCell=c.resource;
							 cc=c;
						 }
					 }
					 else{
						 if(map[c.x][c.y]>energyCell){
							 energyCell=map[c.x][c.y];
							 cc=c;
						 }
					 }		 
				 }
			 }
		 }
		 
		 //once the cell is found, consume from it and move there
		 consume(cc);
		 grid.moveTo(this, cc.x,cc.y);
		 space.moveTo(this, cc.x,cc.y);
	}
	
	/**
	 * The general step method that selects relevant scenario options to run. 
	 */
	 @ScheduledMethod(start = 0, interval = 1,priority = ScheduleParameters.RANDOM_PRIORITY)
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
		 if(this.maxEnergy==this.energy)
			 reproduce();
		 
		 spendEnergy();
		 
		 if(this.energy<=0)
			 RunState.getSafeMasterContext().remove(this);

	 }
	 
	 /**
	  * A move based on probability of moving to an area based on resources in the area.
	  */
	 public void probabilityMove(){
		 List<GridCell<Object>> neighbourhood=getNeighbourhood();
		 
		 Iterator<GridCell<Object>> ic = neighbourhood.iterator();
		 
		Map<Cell,Double>resourcesC=new HashMap<Cell,Double>();
		
		//iterate over the cells and move to the one based on a probability, which is based on its resources
		 double energyCell=0;
		 while(ic.hasNext()){
			 GridCell<Object> gc = ic.next();
			 
			 Iterator<Object> gi = gc.items().iterator();
			 while(gi.hasNext()){
				 Object o = gi.next();
				 if(o instanceof Cell){
					 Cell c = (Cell)o;
					 resourcesC.put(c, c.resource);
					 
					 if(!memory)
						 energyCell+=c.resource;
					 else
						 energyCell+=map[c.x][c.y];
				 }
			 }
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
		 
		 consume(chosen);
		 grid.moveTo(this, chosen.x,chosen.y);
		 space.moveTo(this, chosen.x,chosen.y);
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
		 List<GridCell<Object>> neighbourhood=getNeighbourhood();
		 
		 for(GridCell<Object> gc: neighbourhood){
			 
			 Iterator<Object> gi = gc.items().iterator();
			 
			 while(gi.hasNext()){
				 Object o = gi.next();
				 if(o instanceof Cell){
					 Cell c = (Cell)o;
		
					 map[c.x][c.y]=(c.resource+map[c.x][c.y])/2.0;
					 break;
				 }				 
			}
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
		 if(c.resource-energyDiff>0)
			 addEnergy=energyDiff;
		 
		 else
			 addEnergy=c.resource;
		 
		 c.resource=Math.max(0.0,c.resource-energyDiff);
		 this.energy=Math.min(this.energy+addEnergy,100.0);
	 }
	 
	 /**
	  * Simple reproduction based on using energy.
	  * The agent uses 1/2 their energy to reproduce and give the new agent 1/2 their energy.
	  */
	 public void reproduce(){
		
		 //here another agent is created then half the energy is given to that agent and the other half is kept by the agent reproducing
		 Agent agent = new Agent(this.space,this.grid);
		 agent.energy=this.energy/2.0;
		 this.energy=this.energy/2.0;
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
		 this.energy=Math.max(0.0,this.energy-this.energyCost);
	 }
	 
	 /**
	  * The neighbourhood surrounding the cells of choice
	  * @return a list of the neighbourhood
	  */
	 public List<GridCell<Object>> getNeighbourhood(){
			
		 //This method gets the cells around an agent (usina Moore neighbourhood)
			GridPoint pt = grid.getLocation(this);
			
			 GridCellNgh<Object> nghCreator = new GridCellNgh<Object>(grid, pt,
					   Object.class, 1,1);
			List<GridCell<Object>> gridCells = nghCreator.getNeighborhood(true);
			
			return gridCells;
		}


	public Double getEnergy() {
		return energy;
	}


	public void setEnergy(Double energy) {
		this.energy = energy;
	}
	
	
 }



