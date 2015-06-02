package Transmission;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import repast.simphony.engine.environment.RunEnvironment;
import repast.simphony.engine.environment.RunState;
import repast.simphony.engine.schedule.ScheduleParameters;
import repast.simphony.engine.schedule.ScheduledMethod;
import repast.simphony.parameter.Parameters;
import repast.simphony.query.space.grid.GridCell;
import repast.simphony.query.space.grid.GridCellNgh;
import repast.simphony.random.RandomHelper;
import repast.simphony.space.continuous.ContinuousSpace;
import repast.simphony.space.continuous.NdPoint;
import repast.simphony.space.grid.Grid;
import repast.simphony.space.grid.GridPoint;

/**
 * This is the agent class that contains the variables and methods of the agent.
 */
public class Agent {

	/**This is the the transmission type running in the simulation*/
	String transmissionType="";
	
	/**The number of traits running in a simulation*/
	int nTraits=0;
	
	/**The replacement rate of an agent, where this variable controls how fast or likely an agent will reproduce himself/herself*/
	double replacementRate=0d;
	
	/**This controls how often an agent's traits will change*/
	double innovationRate=0d;
	
	/**This is the cultural traits that are expressed as a string (for output purposes only)*/
	String culturalTraits;
	
	/**The list that carries the traits in the simulation*/
	List<Integer>traits = new ArrayList<Integer>();
	
	/**The continuous space in which the agent operates in*/
	private ContinuousSpace<Object> space;
	
	/**A grid that reflects the space the agent is in*/
	private Grid<Object> grid;

	/**The range in which traits can vary (e.g., 0-9 would mean 0-9 possible values for any given trait)*/
	public int traitRange;

	public Agent(){
		
	}
	
	/**
	 * The constructor for an agent.
	 * This creates agents when they are needed (i.e, at the beginning and during runtime. 
	 * @param space the space in which an agent operates in.
	 * @param grid the grid in which an agent operators in.
	 */
	public Agent(ContinuousSpace<Object> space, Grid<Object>grid){
		
		//An agent's parameters are obtained here and instantiated in the simulation
		Parameters p = RunEnvironment.getInstance().getParameters();
		this.grid=grid;
		this.nTraits = (Integer)p.getValue("nTraits");
		this.traitRange = (Integer)p.getValue("traitRange");
		
		this.transmissionType =(String)p.getString("transmissionType");
		this.innovationRate=RunEnvironment.getInstance().getParameters().getDouble("innovationRate");
		
		//add the traits based on the range and the number of them
		for(int j=0; j < nTraits;j++){
			int tR=RandomHelper.nextIntFromTo(0, traitRange-1);
			this.traits.add(tR);
		}		
		this.space=space;
		this.replacementRate=p.getDouble("replacementRate");
	}
	
	/**
	 * This randomly changes a specific index value in a list of traits
	 * @param useTraits the traits list to change
	 * @param v the index value to change
	 */
	public void evolveSpecificValue(List<Integer> useTraits,int v){
		
		int n=useTraits.get(v);
		
		int r=RandomHelper.nextIntFromTo(0, traitRange-1);
		n=r;
		useTraits.remove(v);
		useTraits.add(v,n);
	}
	
	/**
	 * This method controls the evolution of a given trait by random change.
	 * @param useTraits
	 */
	public void evolveValue(List<Integer> useTraits){
		
		//this changes the trait values by removing the old and randomly adding a new type of value under a given range.
		int v=RandomHelper.nextIntFromTo(0,  nTraits-1);
		int n=useTraits.get(v);
		
		int r=RandomHelper.nextIntFromTo(0, traitRange-1);
		n=r;
		useTraits.remove(v);
		useTraits.add(v,n);
	}
	
	/**
	 * An agent moves from one location to another random location.
	 */
	public void move(){
		
		//the agent here selects a location to move based on a 360 degree view and given distance of movement
		int v=RandomHelper.nextIntFromTo(1, 360);
		Parameters p = RunEnvironment.getInstance().getParameters();
		double moveDistance=p.getDouble("moveDistance");
		
		//move by vector in a given direction
		space.moveByVector(this, moveDistance, Math.toRadians(v),0);
				
		//move to the given space chosen
		grid.moveTo(this, 
				(int)Math.round(space.getLocation(this).getX()),
				(int)Math.round(space.getLocation(this).getY()));
	}
	
	/**
	 * This method simply removes the agent from the simulation.
	 * @param a an agent to remove from the simulation.
	 */
	 public void death(Agent a) {
		RunState.getSafeMasterContext().remove(a);
	}
	 
	 /**
	  * This is a method that controls the simulation steps for each agent. As the simulation begins, this method is called
	  * automatically. The method then selects the appropriate scenario type and launches relevant methods. Users setup the type of 
	  * scenario in the parameters.xml file.
	  */
	 @ScheduledMethod(start = 0, interval = 1,priority = ScheduleParameters.RANDOM_PRIORITY)
	 public void step(){
		//first move the agent
		 move();
		 
		//the step method enables some conditional choices for what type of simulation is being run
		if(transmissionType.equalsIgnoreCase("vertical")){
			replacement();
		}
		
		if(transmissionType.equalsIgnoreCase("encounter")){
			encounter("encounter");
		}
		
		if(transmissionType.equalsIgnoreCase("prestige")){
			encounter("prestige");	
		}
		
		if(transmissionType.equalsIgnoreCase("conformist")){
			populationEncounter();
		}
		
		doResults();
	 }
	 
	 /**
	  * This is a neighbourhood search and encounter for an agent where the agent finds someone and then evolves
	  * their cultural traits based on an encounter.
	  * @param encounter the encounter type (regular encounter or prestige) 
	  */
	public void encounter(String encounter){
		List<GridCell<Agent>> gridCells=getNeighbourhood();
				
		//after you get the neighourhood then you search for the appropriate cell and agent in that cell
		if(gridCells.size()>0){
			
			// check if there are suitable agents
			boolean run=false;
			Iterator<GridCell<Agent>>ia = gridCells.iterator();
			while(ia.hasNext()){
				GridCell gc=ia.next();
				Iterator<Agent>iaa=gc.items().iterator();
				while(iaa.hasNext()){
					Agent aa=iaa.next();
					if(aa!=this && aa!=null)
						run=true;
					}
				} 
			
			Agent a = this;
			
			double innovationRate=RunEnvironment.getInstance().getParameters().getDouble("innovationRate");
			double rr=RandomHelper.nextDouble();
			
			//then, based on the type of simulation, you choose the options of how to evolve
			int v=-1;
			if(encounter.equals("encounter") && run){
				
				//for encounter get an agent from a random location
				while(a==this || a==null){
					int i=RandomHelper.nextIntFromTo(0, gridCells.size()-1);
					int x=gridCells.get(i).getPoint().getX();
					int y=gridCells.get(i).getPoint().getY();
					a=(Agent)grid.getObjectAt(x,y);
				}

				//evolve the agent's traits
				if(a!=null && a!=this)
					v=changeEvolve(a.traits,traits);
			}
			else{

				//here we see based on probability which agent an agent will copy one trait
				if(run)
					v=prestige(gridCells);	
			}
			
			//see if there is a random change the trait evolves
			if(rr<innovationRate && v!=-1)
				evolveSpecificValue(traits,v);
		}
	}
	
	/**
	 * This evolves based on prestige values such that:
	 * probability P of copy of each neighbour as (1+traits[prestigeIndex])/sum(all neighbours (traits[prestigeIndex]+1))
	 * then select a neighbour with computed Ps and copy its value at prestigeIndex (index location of prestige value)
	 * @param gridCells the neighbourhood of cells
	 */
	public int prestige(List<GridCell<Agent>> gridCells){
		
		double nP=neighborProbability(gridCells);
		Parameters p = RunEnvironment.getInstance().getParameters();
		double rV=RandomHelper.nextDouble();
		double oldRange=0;
		int v=(Integer)p.getValue("prestigeIndex");
		Agent a=null;
			
			while(a==null){
				int r = RandomHelper.nextIntFromTo(0, gridCells.size()-1);
				Iterable<Agent>ia=gridCells.get(r).items();
				if(ia!=null){
					Iterator<Agent>iia=ia.iterator();
					while(iia.hasNext()){
						a=iia.next();
						if(a!=this && a!=null)
							break;
						else
							continue;
					}
				}
			}
		
		int index=RandomHelper.nextIntFromTo(0, a.traits.size()-1);
		v=index;
		int t=a.traits.get(index);
		
		double prob=((1+a.traits.get(v))/(nP+1));
		
		if(prob<RandomHelper.nextDouble()){
			traits.remove(index);
			traits.add(index,t);
		}
		else
			v=-1;
		
		return v;
	}
	
	/**
	 * Summed value of the prestige trait for all agents in a neighbourhood
	 * @param agents the agents from a neighbourhood
	 * @return the summed prestige value
	 */
	public double neighborProbability(List<GridCell<Agent>> agents){
		double value=0;
		Parameters p = RunEnvironment.getInstance().getParameters();
		
		Iterator<GridCell<Agent>> ci = agents.iterator();
		while(ci.hasNext()){
			GridCell<Agent>gc = ci.next();
			Iterator<Agent> ia = gc.items().iterator();
			
			while(ia.hasNext()){
				Agent a = ia.next();
				if(a==this)
					continue;
				value+=a.traits.get((Integer)p.getValue("prestigeIndex"));
			}
		}
		
		return value;
	}
	
	/**
	 * The neighbourhood of cells that is obtained from a given region
	 * @return
	 */
	public List<GridCell<Agent>> getNeighbourhood(){
		
		//here, the neighbourhood searched is based on the radius of the search and the grid space
		Parameters p = RunEnvironment.getInstance().getParameters();
		
		double rad=p.getDouble("interactionRadius");
		
		GridPoint pt = grid.getLocation(this);
		
		 GridCellNgh<Agent> nghCreator = new GridCellNgh<Agent>(grid, pt,
				   Agent.class, (int)rad, (int)rad);
		List<GridCell<Agent>> gridCells = nghCreator.getNeighborhood(false);
		
		return gridCells;
	}
	
	/**
	 * This method does the population encounter type scenario.
	 */
	public void populationEncounter(){
		
		//a list of cells and agents are searched and then the values are changed as appropriate based on the best fit search
		List<GridCell<Agent>> gridCells=getNeighbourhood();
		
		double innovationRate=RunEnvironment.getInstance().getParameters().getDouble("innovationRate");
		double rr = RandomHelper.nextDouble();
		int v=RandomHelper.nextIntFromTo(0,  nTraits-1);
		
		
		if(gridCells.size()>0){
			
			Map<Integer,Integer> counts= new HashMap<Integer,Integer>();
			
			int greatestValue=0;
			int gValue=0;
		
			for(GridCell gc:gridCells){
				
				Iterator<Agent> aci = gc.items().iterator();
				while(aci.hasNext()){
					Agent a = aci.next();
						if(a==this)
							continue;
						
						int results=a.traits.get(v);
						if(counts.containsKey(results)){
							counts.put(results, counts.get(results)+1);
						
							if(counts.get(results)>gValue){
								greatestValue=results;
								gValue=counts.get(results);
							}
						}
						else{
							counts.put(results, 1);
							if(gValue==0){
								gValue=1;
								greatestValue=results;
							}
							
						}
					}
				}
				if(gValue==0)
					return;
				
				traits.remove(v);
				traits.add(v, greatestValue);
				
				if(rr<innovationRate)
					evolveSpecificValue(traits,v);	
		}
	}
	
	/**
	 * This is similar to the evolve traits method except it takes two lists (one set of traits; lTraits) and then
	 * it gives it to another (oTraits)
	 * @param lTraits the list where you have one set of traits to give
	 * @param oTraits the list where you have traits being received by an agent
	 * @return the location of the new value changed
	 */
	public int changeEvolve(List<Integer>lTraits, List<Integer>oTraits){
		
		Parameters p = RunEnvironment.getInstance().getParameters();
		int nTraits = (Integer)p.getValue("nTraits");
		
		//get a random trait
		int v=RandomHelper.nextIntFromTo(0,  nTraits-1);
		int n=lTraits.get(v);
		
		//remove the old trait
		oTraits.remove(v);
		
		//replace with the new
		oTraits.add(v,n);
		
		return v;
	}
	
	/**
	 * This method does the replacement for an agent, where the agent then dies at the end.
	 * The replacement leads to the transmission of the "genes."
	 */
	public void replacement(){
			double d = RandomHelper.nextDouble();
			
			//reproduce based on a random value and if the random value is below the given rate
			if(replacementRate>d){
				Agent agent = new Agent(this.space,this.grid);
				
				int s=RunState.getSafeMasterContext().getObjects(Agent.class).size();
				RunState.getSafeMasterContext().add(agent);
				
				Agent a=null;
				
				int get=RandomHelper.nextIntFromTo(0, s-1);
				a=(Agent)RunState.getSafeMasterContext().getObjects(Agent.class).get(get);
				
				agent.traits=traits;
				
				double rr=RandomHelper.nextDouble();
				if(innovationRate>rr)
					agent.evolveValue(agent.traits);
				
				RunState.getSafeMasterContext().add(agent);
				space.moveTo(agent, space.getLocation(this).getX(),space.getLocation(this).getY());
				grid.moveTo(agent, grid.getLocation(this).getX(),grid.getLocation(this).getY());
		
				//agent dies once it reproduces 
				death(a);
	
	//			System.out.println(RunState.getSafeMasterContext().size());
			}
		}

	/**
	 * A method to convert the list of traits to a String.
	 */
	public void doResults(){
		
		//method to output the results, as the output is not a typical way in which Repast handles outputs, this method is done and 
		//makes it a string
		culturalTraits="";
		for(int i=0;i<traits.size();i++){
			culturalTraits+=traits.get(i);
			
			if(i<traits.size()-1)
				culturalTraits+="-";
		}
		
	}


	public String getCulturalTraits() {
		return culturalTraits;
	}

	public void setCulturalTraits(String culturalTraits) {
		this.culturalTraits = culturalTraits;
	}

	
 }