package Transmission;

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
import repast.simphony.space.grid.Grid;
import repast.simphony.space.grid.GridBuilderParameters;
import repast.simphony.space.grid.SimpleGridAdder;
import repast.simphony.space.grid.WrapAroundBorders;

/**
 * This is the Transmission context which is used in the simulation initialization phase.
 * 
 */
public class TransmissionContext implements ContextBuilder<Object>{
	
	/**
	 * This is the context build method which is launched when the model is initialized.
	 * It basically builds the agents and creates the simulation space.
	 * 
	 */
	@Override
	public Context build(Context<Object> context) {
		
		//the simulation is built and instantiated here, with the build method overriding the Repast method.
		
		Parameters p = RunEnvironment.getInstance().getParameters();
		int xDim = (Integer)p.getValue("xDim");
		int yDim = (Integer)p.getValue("yDim");
		int end = (Integer)p.getValue("timeStep");
		
		//the space in the simulation
		ContinuousSpaceFactory spaceFactory = ContinuousSpaceFactoryFinder
				.createContinuousSpaceFactory(null);
		
		ContinuousSpace<Object> space = spaceFactory.createContinuousSpace(
				"space", context, new RandomCartesianAdder<Object>(),
				new repast.simphony.space.continuous.WrapAroundBorders(),xDim, yDim);
		
		GridFactory gridFactory = GridFactoryFinder.createGridFactory(null);
		
		Grid<Object> grid = gridFactory.createGrid("grid", context,
				new GridBuilderParameters<Object>(new WrapAroundBorders(),
						new SimpleGridAdder<Object>(), true, xDim, yDim));
		 
		Integer nAgents=(Integer)p.getValue("nAgents");
				
		//the number of agents are built
		for(int i=0; i < nAgents ; i++){
			Agent agent = new Agent(space,grid);
			context.add(agent);
			double x=Math.round(RandomHelper.nextIntFromTo(0, xDim-1));
			double y=Math.round(RandomHelper.nextIntFromTo(0, yDim-1));
			space.moveTo(agent, x,y);
			grid.moveTo(agent, (int)x,(int)y);
		}
		
		Outputter o = new Outputter();
		
		//the outputter and agents are added to the context
		context.add(o);
		
		//simulation time of when to end the simulation is set here
		RunEnvironment.getInstance().endAt(end);
		return context;
		
	}
	
}
