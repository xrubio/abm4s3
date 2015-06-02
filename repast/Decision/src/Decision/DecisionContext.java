package Decision;

import repast.simphony.context.Context;
import repast.simphony.context.space.continuous.ContinuousSpaceFactory;
import repast.simphony.context.space.continuous.ContinuousSpaceFactoryFinder;
import repast.simphony.context.space.grid.GridFactory;
import repast.simphony.context.space.grid.GridFactoryFinder;
import repast.simphony.dataLoader.ContextBuilder;
import repast.simphony.engine.environment.RunEnvironment;
import repast.simphony.parameter.Parameters;
import repast.simphony.random.RandomHelper;
import repast.simphony.space.continuous.ContinuousSpace;
import repast.simphony.space.continuous.RandomCartesianAdder;
import repast.simphony.space.grid.BouncyBorders;
import repast.simphony.space.grid.Grid;
import repast.simphony.space.grid.GridBuilderParameters;
import repast.simphony.space.grid.SimpleGridAdder;


public class DecisionContext implements ContextBuilder<Object>{
	
	@Override
	public Context build(Context<Object> context) {
		
		//The build method is used to build the simulation and instantiate agents and objects. 
		//This is a method from Repast that is overridden in the simulation
		Parameters p = RunEnvironment.getInstance().getParameters();
		int xDim = (Integer)p.getValue("xDim");
		int yDim = (Integer)p.getValue("yDim");
		double end = (Double)p.getValue("nSteps");
		
		//The spaces used in the simulation is where the agent interacts in the simulation
		ContinuousSpaceFactory spaceFactory = ContinuousSpaceFactoryFinder
				.createContinuousSpaceFactory(null);
		ContinuousSpace<Object> space = spaceFactory.createContinuousSpace(
				"space", context, new RandomCartesianAdder<Object>(),
				new repast.simphony.space.continuous.BouncyBorders(),xDim, yDim);
		GridFactory gridFactory = GridFactoryFinder.createGridFactory(null);
		Grid<Object> grid = gridFactory.createGrid("grid", context,
				new GridBuilderParameters<Object>(new BouncyBorders(),
						new SimpleGridAdder<Object>(), true, xDim, yDim));
		
		
		//we take the number of agents and build them here
		int numAgents = (Integer)p.getValue("nAgents");
		
		for(int i=0; i < numAgents ; i++){
			Agent agent = new Agent(space,grid);
			context.add(agent);
			double x=RandomHelper.nextIntFromTo(0, xDim-1);
			double y=RandomHelper.nextIntFromTo(0, yDim-1);
			space.moveTo(agent, x,y);
			grid.moveTo(agent, (int)Math.round(x),(int)Math.round(y));
		}
		
		for(int i=0; i < xDim; i++){
			
			for(int j=0; j < yDim; j++) {
				Cell c = new Cell(space,grid,i,j);
				context.add(c);
				grid.moveTo(c, c.x,c.y);
				space.moveTo(c, c.x,c.y);
			}
		}
		
		//this sets a definite time ending to the simulation
		RunEnvironment.getInstance().endAt(end);
		return context;
		
	}
	
}
