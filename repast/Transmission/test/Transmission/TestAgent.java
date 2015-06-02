package Transmission;

import java.awt.geom.Point2D;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import repast.simphony.context.Context;
import repast.simphony.context.DefaultContext;
import repast.simphony.context.space.continuous.ContinuousSpaceFactory;
import repast.simphony.context.space.continuous.ContinuousSpaceFactoryFinder;
import repast.simphony.context.space.grid.GridFactory;
import repast.simphony.context.space.grid.GridFactoryFinder;
import repast.simphony.engine.environment.RunEnvironment;
import repast.simphony.engine.environment.RunState;
import repast.simphony.parameter.Parameters;
import repast.simphony.query.space.grid.GridCell;
import repast.simphony.query.space.grid.GridCellNgh;
import repast.simphony.random.RandomHelper;
import repast.simphony.space.continuous.ContinuousSpace;
import repast.simphony.space.continuous.NdPoint;
import repast.simphony.space.continuous.RandomCartesianAdder;
import repast.simphony.space.grid.Grid;
import repast.simphony.space.grid.GridBuilderParameters;
import repast.simphony.space.grid.GridPoint;
import repast.simphony.space.grid.SimpleGridAdder;
import repast.simphony.space.grid.WrapAroundBorders;
import Transmission.Agent;
import static org.junit.Assert.*;

import org.junit.Test;

/**
 * Test class for Agent in the transmission model.
 * 
 * @author 
 *
 */
public class TestAgent {
	
	/**The context to put agents in*/
	static Context context;
	
	/**The grid space the agent belongs to*/
	static Grid<Object> grid;
	
	/**The continuous space the agent belongs to*/
	static ContinuousSpace<Object> space;
	
	/**the grid cells the agent is in*/
	private List<GridCell<Agent>> gridCells;
	
	/**
	 * Loads the context, space, and grid into the tests
	 */
	static {
		context = new DefaultContext();
		
		ContinuousSpaceFactory spaceFactory = ContinuousSpaceFactoryFinder
				.createContinuousSpaceFactory(null);
		
		 space = spaceFactory.createContinuousSpace(
				"space", context, new RandomCartesianAdder<Object>(),
				new repast.simphony.space.continuous.WrapAroundBorders(),10,10);
		
		GridFactory gridFactory = GridFactoryFinder.createGridFactory(null);
		
		grid = gridFactory.createGrid("grid", context,
				new GridBuilderParameters<Object>(new WrapAroundBorders(),
						new SimpleGridAdder<Object>(), true, 10,10));
	}

	
	@Test
	/**
	 * Test the create an agent method and move the agent
	 */
	public void testCreateAgent(){
	
		for(int i=0; i < 100; i++){
			Agent agent = new Agent();
			for(int j=0; j < 5;j++){
				agent.traits.add(1);
			}
			context.add(agent);
			double x=RandomHelper.nextIntFromTo(0, 10-1);
			double y=RandomHelper.nextIntFromTo(0, 10-1);
			space.moveTo(agent, x,y);
			grid.moveTo(agent, (int)x,(int)y);
			
			assertTrue((int)space.getLocation(agent).getX()==grid.getLocation(agent).getX());
		}
		assertTrue(grid.getDimensions().getHeight()==10);
	}
	
	/**
	 * This creates the neighborhood for a given agent
	 * @param agent
	 * @return
	 */
	public List<GridCell<Agent>> getNeighborhood(Agent agent){
		
		double rad=1.0;
		GridPoint pt=grid.getLocation(agent);
		GridCellNgh<Agent> nghCreator = new GridCellNgh<Agent>(grid, pt,
				   Agent.class, (int)rad, (int)rad);
		gridCells = nghCreator.getNeighborhood(false);
		
		return gridCells;
	}
	
	@Test
	/**
	 * Tests that the neighborhood is created
	 */
	public void testNeighborhood(){
		testCreateAgent();
		
		for(Object o:context){
			if(o instanceof Agent){
				Agent a = (Agent)o;
				getNeighborhood(a);
				assertTrue(gridCells.size()==8);
			}
		}
	}
	
	@Test
	/**
	 * Tests to see that the agent is moving accurately.
	 */
	public void testMove(){
		testCreateAgent();
		
		Agent agent = (Agent)context.getObjects(Agent.class).iterator().next();
		NdPoint np=space.getLocation(agent);
		GridPoint g1=grid.getLocation(agent);
		
		//move by vector in a given direction
		space.moveByVector(agent, 1.0, Math.toRadians(30),0);
				
		//move to the given space chosen
		grid.moveTo(agent, 
				(int)Math.round(space.getLocation(agent).getX()),
				(int)Math.round(space.getLocation(agent).getY()));
		
		GridPoint g2=grid.getLocation(agent);
		
		assertTrue(1==Math.abs(g1.getX()-g2.getX()));
	}
	
	@Test
	/**
	 * This tests to see if the replacement method works correctly.
	 */
	public void testReplacement(){
		testCreateAgent();
		Agent agent=(Agent)context.getObjects(Agent.class).iterator().next();
		
		agent.evolveValue(agent.traits);
	}
	
	@Test
	/**
	 * Tests to see if values are accurately evolved in traits
	 */
	public void testEvolveValue(){
			testCreateAgent();
			List traits=((Agent)context.getObjects(Agent.class).iterator().next()).traits;
			
			//this changes the trait values by removing the old and randomly adding a new type of value under a given range.
			int v=0;
			int n=(int) traits.get(v);
			
			int r=RandomHelper.nextIntFromTo(1, 2);
			n=r;
			traits.remove(v);
			traits.add(v,n);
			
			assertTrue((int)traits.get(0)!=0);
		
	}
	
	@Test
	/**
	 * This evolves a trait value in encounter
	 */
	public void testChangeEvolve(){
		testCreateAgent();
		Agent agent=(Agent)context.getObjects(Agent.class).iterator().next();
	
		int v=1;
		int n=2;
		
		//remove the old trait
		agent.traits.remove(v);
		
		//replace with the new
		agent.traits.add(v,n);
		
		assertTrue(agent.traits.get(v)==n);
	}
	
	@Test
	/**
	 * This tests the prestige mechanism, which finds a prestige trait and gives to an agent
	 */
	public void testPrestige(){
		testCreateAgent();
		Agent agent = (Agent)context.iterator().next();
		double nP=totalNeighborProb();
		double oldRange=0d;
		double rV=0.5;
		Agent a=null;
		
		Iterator<GridCell<Agent>> ci = gridCells.iterator();
		while(ci.hasNext()){
			GridCell<Agent>gc = ci.next();
			Iterator<Agent> ia = gc.items().iterator();
			
			while(ia.hasNext()){
				Agent aa = ia.next();
				if(aa==agent)
					continue;
				double pp=(1+aa.traits.get(0))/(1+nP);
				
				if((rV>oldRange)&& (rV<(oldRange+pp))){
					a=aa;
					
					//once the trait is found then the agent removes the old trait and adds the new one
					int tV=a.traits.get(0);
					agent.traits.remove(0);
					agent.traits.add(0, tV);
					
					assertTrue(oldRange<0.5);
				}
				else{
					oldRange+=pp;
				}
			}
		}
	}
	
	/**
	 * This is the total neighborhood probability.
	 * @return
	 */
	public double totalNeighborProb(){
		double value=0;
		Agent agent = (Agent)context.iterator().next();
		Iterator<GridCell<Agent>> ci = this.getNeighborhood(agent).iterator();
		while(ci.hasNext()){
			GridCell<Agent>gc = ci.next();
			Iterator<Agent> ia = gc.items().iterator();
			
			while(ia.hasNext()){
				Agent a = ia.next();
				if(a==agent)
					continue;
				value+=a.traits.get(0);
			}
		}
		
		return value;
	}
	
	@Test
	/**
	 * The conformist method is tested.
	 */
	public void testConformist(){
		testCreateAgent();
		Agent agent = (Agent)context.iterator().next();
		getNeighborhood(agent);
		Iterator<GridCell<Agent>> ic = gridCells.iterator();
		
		Map<Integer,Integer> counts= new HashMap<Integer,Integer>();
		
		int greatestValue=0;
		int gValue=0;
	
		while(ic.hasNext()){
			GridCell<Agent> gc=ic.next();
			Iterator<Agent> aci = gc.items().iterator();
			while(aci.hasNext()){
				Agent a = aci.next();
					if(a==agent)
						continue;
					
					int results=a.traits.get(1);
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
			
			agent.traits.remove(1);
			agent.traits.add(1, greatestValue);
			assertTrue(agent.traits.get(1)==1);
	}

}
