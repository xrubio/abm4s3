package Decision;

import static org.junit.Assert.assertTrue;

import java.util.List;

import org.junit.Test;

import repast.simphony.context.Context;
import repast.simphony.context.DefaultContext;
import repast.simphony.context.space.continuous.ContinuousSpaceFactory;
import repast.simphony.context.space.continuous.ContinuousSpaceFactoryFinder;
import repast.simphony.context.space.grid.GridFactory;
import repast.simphony.context.space.grid.GridFactoryFinder;
import repast.simphony.query.space.grid.GridCell;
import repast.simphony.query.space.grid.GridCellNgh;
import repast.simphony.random.RandomHelper;
import repast.simphony.space.continuous.ContinuousSpace;
import repast.simphony.space.continuous.RandomCartesianAdder;
import repast.simphony.space.grid.Grid;
import repast.simphony.space.grid.GridBuilderParameters;
import repast.simphony.space.grid.GridPoint;
import repast.simphony.space.grid.SimpleGridAdder;
import repast.simphony.space.grid.WrapAroundBorders;
import Decision.Agent;

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
			agent.map=new double[10][10];
			agent.energyCost=9.0;
			agent.maxEnergy=100.0;
			agent.setEnergy(50.0);
			context.add(agent);
			double x=RandomHelper.nextIntFromTo(0, 10-1);
			double y=RandomHelper.nextIntFromTo(0, 10-1);
			space.moveTo(agent, x,y);
			grid.moveTo(agent, (int)x,(int)y);
			
			agent.grid=grid;
			agent.space=space;
			assertTrue((int)space.getLocation(agent).getX()==grid.getLocation(agent).getX());
		}
		assertTrue(grid.getDimensions().getHeight()==10);
	}
	
	/*
	 *Create cells for agents to opperate in. 
	 */
	public void createCells(){
		for(int i=0; i < 10; i++){
			
			for(int j=0; j < 10; j++) {
				Cell c = new Cell();
				c.x=i;
				c.y=j;
				c.maxResource=100;
				c.resource=70;
				c.resoureGrowthRate=2.0;
				context.add(c);
				grid.moveTo(c, c.x,c.y);
				space.moveTo(c, c.x,c.y);
			}
		}
	}
	
	@Test 
	/**
	 * Test the memory mechanism
	 */
	public void testMemoryMechanism(){
		testCreateAgent();
		createCells();
		
		Agent agent = (Agent)context.getObjects(Agent.class).iterator().next();
		agent.memoryMechanism();
		
		for(int i=0; i < agent.map.length;i++){
			for(int j=0; j < agent.map.length;j++){
				assertTrue(agent.map[i][j]==0.0 || agent.map[i][j]==35.0 || agent.map[i][j]==10.0);
			}
		}
		
	}
	
	@Test
	/**
	 * Test the greedy no memory type of simulation.
	 */
	public void testGreedyNoMemory(){
		testCreateAgent();
		createCells();
		
		Agent agent = (Agent)context.getObjects(Agent.class).iterator().next();
		agent.memory=false;
		agent.greedyMove();
		assertTrue(agent.getEnergy()==100.0);
	}
	
	@Test
	/**
	 * Test greed with memory type of simulation.
	 */
	public void testGreedMemory(){
		testCreateAgent();
		createCells();
		
		Agent agent = (Agent)context.getObjects(Agent.class).iterator().next();
		agent.memory=true;
		agent.greedyMove();
		assertTrue(agent.getEnergy()==100.0);
	}
	
	@Test
	/**
	 * Test probability no memory type of simulation.
	 */
	public void testProbabilityNoMemory(){
		testCreateAgent();
		createCells();
		
		Agent agent = (Agent)context.getObjects(Agent.class).iterator().next();
		agent.memory=false;
		agent.probabilityMove();
		assertTrue(agent.getEnergy()==100.0);
	}
	
	@Test
	/**
	 * Test probability with memory type of simulation.
	 */
	public void testProbabilityMemory(){
		testCreateAgent();
		createCells();
		
		Agent agent = (Agent)context.getObjects(Agent.class).iterator().next();
		agent.memory=true;
		agent.probabilityMove();
		assertTrue(agent.getEnergy()==100.0);
	}
	
	
}
