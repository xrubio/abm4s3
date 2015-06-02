package Transmission;

import java.awt.Color;

import repast.simphony.visualizationOGL2D.DefaultStyleOGL2D;

/**
 * The 2D style class for agents.   
 *
 * @author 
 */

public class AgentStyle2D extends DefaultStyleOGL2D {

	/**
	 * The method below simply returns a color to be used in visualization during the simulation running (colors of agents)
	 * change as their traits evolve.
	 */
	@Override
	public Color getColor(Object o) {
		
			//this method overrides the base method in DefaultStyleOGL2D from repast and applies the traits of the agent in the simulation
			if(!(o instanceof Agent))
				return null;
			Agent a = (Agent)o;
			
			String traits=a.getCulturalTraits();
			if(traits==null)
				return Color.BLUE;
			String[] sTraits=traits.split("-");
	//		double colorRange=(256/(double)sTraits.length);
			
			double r=Double.parseDouble(sTraits[0])/(double)a.traitRange;
			double g=Double.parseDouble(sTraits[1])/(double)a.traitRange;
			double b=Double.parseDouble(sTraits[2])/(double)a.traitRange;
			
			Color c = new Color((float)r,(float)g,(float)b);
			
			return c;
	}
	
}
