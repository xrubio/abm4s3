package Decision;

import repast.simphony.engine.environment.RunEnvironment;
import repast.simphony.engine.schedule.ScheduleParameters;
import repast.simphony.engine.schedule.ScheduledMethod;
import repast.simphony.parameter.Parameters;
import repast.simphony.random.RandomHelper;
import repast.simphony.space.continuous.ContinuousSpace;
import repast.simphony.space.grid.Grid;

public class Cell {
	
	/**The grid the cell is in*/
	public Grid grid;
	
	/**The continuous space the cell is in*/
	public ContinuousSpace space;
	
	/**The maximum resources that a cell can have*/
	public int maxResource;
	
	/**The amount of resources a cell can have*/
	public double resource;
	
	/*The resource growth of a cell*/
	public double resoureGrowthRate;
	
	/**The x location of a cell*/
	int x=0;
	
	/**The y location of a cell*/
	int y=0;
	
	/**
	 * The cell object where an agent moves to.
	 * 
	 * @param space the continous space to put the cell in
	 * @param grid the grid space to put the cell in
	 * @param x the x location
	 * @param y the y location
	 */
	public Cell (ContinuousSpace space, Grid grid,int x, int y) {
		
		//Cell gets instantiated here
		Parameters p = RunEnvironment.getInstance().getParameters();
		this.grid=grid;
		this.space=space;
		
		this.maxResource = (Integer)p.getValue("maxResource");
		this.resoureGrowthRate=(Double)p.getValue("resourceGrowthRate");
		this.resource=RandomHelper.nextDoubleFromTo(0, this.maxResource);
	
		this.maxResource=(int)this.resource;
		this.x=x;
		this.y=y;
	}
	
	public Cell (){
		
	}
	
	/**
	 * The default step of the cell, which increases its resources or replenishes them.
	 */
	 @ScheduledMethod(start = 2, interval = 2,priority = ScheduleParameters.LAST_PRIORITY)
	public void step(){
		 //all the cell does in its behaviour is add resources. 
		 this.resource=this.resoureGrowthRate+this.resource;
		 if(this.resource>this.maxResource)
			 this.resource=this.maxResource;
	}

	public double getResource() {
		return resource;
	}

	public void setResource(double resource) {
		this.resource = resource;
	}
	 
	
	
	

}
