package Transmission;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;






import org.apache.commons.io.FileUtils;

import repast.simphony.engine.environment.RunEnvironment;
import repast.simphony.engine.environment.RunState;
import repast.simphony.engine.schedule.ScheduleParameters;
import repast.simphony.engine.schedule.ScheduledMethod;
import repast.simphony.parameter.Parameters;

/**
 * The output class that writes the output of the simulation specified for this simulation.
 * 
 * The user could use though the standard Repast output text standards.
 * 
 *
 */
public class Outputter {
	
	/**The list of String names of different traits used in the simulation.*/
	List<String>outputStrings=new ArrayList<String>();
	
	/**The list of the output read from a text file*/
	public List<String>output;
	
	/**The basic name of the output file*/
	String fileName="."+File.separator+"output"+File.separator+"Output";
	
	/**The timestamp used as part of the name for the output file to distinguish runs*/
	private long time;
	
	/**The file object for the output file*/
	private File file;
	
	/**The file writer object used to write to the output file*/
	private FileWriter fileWritter;
	
	/**The buffer writer used to write to the output file in a buffered stream rather than reading the entire file*/
	private BufferedWriter bufferWritter;
	
	/**
	 * This method is called so that the results can be appended and written to an output csv text file.
	 * @param results the results from the agents.
	 */
	public void copyResults(Map<String,Integer> results){
		
		String line="";
		String vOutput="";
		Parameters p = RunEnvironment.getInstance().getParameters();
		
		for(String s : outputStrings){
			double n=0;
			if(!results.containsKey(s))
				n=0;
			else{
				n=(double)results.get(s);
			}
			line+=s+",";
			
			vOutput+=n+",";
		}
		double t=RunEnvironment.getInstance().getCurrentSchedule().getTickCount();
		line="Time Step,"+line;
		vOutput=t+","+vOutput;
		
		int end = (Integer)p.getValue("timeStep");
		
		//need to append file and not read the whole thing.
		
		double tick=RunEnvironment.getInstance().getCurrentSchedule().getTickCount();
			if(tick==end){
				try {
					output=FileUtils.readLines(file);
				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				} 
				output.add(0,line);
				output.add(vOutput);
				try{
					FileUtils.writeLines(file, output);
				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
				return;
			}
		//	return;
//		}
			
		try {
			fileWritter = new FileWriter(file,true);
	        bufferWritter = new BufferedWriter(fileWritter);
	        bufferWritter.write(vOutput+"\n");
	        bufferWritter.close();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} 
			
		
	}
	
	/**
	 * This method is running during the simulation and it simply grabs the results from the agents and puts the
	 * results to a text file.
	 */
	 @ScheduledMethod(start = 0, interval = 1,priority = ScheduleParameters.LAST_PRIORITY)
	public void step(){
		Iterator<Object> ic = RunState.getSafeMasterContext().iterator();
		Map<String,Integer>total=new HashMap<String,Integer>();
		
		while(ic.hasNext()){
			Object o = ic.next();
			if(o==this)
				continue;
			else{
				Agent a = (Agent)o;
				if(a.culturalTraits==null)
					a.doResults();
				if(total.containsKey(a.culturalTraits)){
					total.put(a.culturalTraits, 1+total.get(a.culturalTraits));
				}
				else{
					total.put(a.culturalTraits, 1);
				}
				
				if(!outputStrings.contains(a.culturalTraits))
					outputStrings.add(a.culturalTraits);
			}
		}
		if(RunEnvironment.getInstance().getCurrentSchedule().getTickCount()==0.0){
			time=System.currentTimeMillis();
			this.file=new File(fileName+RunState.getInstance().getRunInfo().getRunNumber()+".csv");
			file.delete();
			if(!file.exists()){
				if(!(new File("."+File.separator+"output").exists()))
						new File("."+File.separator+"output").mkdir();
				try {
					file.createNewFile();
				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
    		}
		}
		copyResults(total);
		
	}

}
