package org.muehleisen.hannes.taxiapp;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.LinkedBlockingDeque;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.zip.ZipInputStream;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.filefilter.SuffixFileFilter;
import org.apache.commons.io.filefilter.TrueFileFilter;
import org.apache.log4j.Logger;
import org.opentripplanner.routing.algorithm.EarliestArrivalSPTService;
import org.opentripplanner.routing.impl.GraphServiceImpl;
import org.opentripplanner.routing.impl.RetryingPathServiceImpl;
import org.opentripplanner.routing.services.PathService;
import org.opentripplanner.routing.spt.GraphPath;

import com.martiansoftware.jsap.FlaggedOption;
import com.martiansoftware.jsap.JSAP;
import com.martiansoftware.jsap.JSAPException;
import com.martiansoftware.jsap.JSAPResult;


// this reads trip data from http://www.andresmh.com/nyctaxitrips/
public class TaxiRoute extends Thread {

	private static Logger log = Logger.getLogger(TaxiRoute.class);

	private String graph;
	private String taxilog;
	private PathService ps = null;
	private long deliveries = 0;

	public TaxiRoute(String graph, String taxilog) {
		this.graph = graph;
		this.taxilog = taxilog;
	}

	@Override
	public void run() {
		log.info(this.getClass().getSimpleName() + " starting...");

		BlockingQueue<Runnable> taskQueue = new LinkedBlockingDeque<Runnable>(
				100);
		ExecutorService ex = new ThreadPoolExecutor(Runtime.getRuntime()
				.availableProcessors(), Runtime.getRuntime()
				.availableProcessors(), Integer.MAX_VALUE, TimeUnit.DAYS,
				taskQueue, new ThreadPoolExecutor.DiscardPolicy());

		// bring up routing service
		log.info("Bringing up OTP Graph Service from '" + graph + "'.");
		GraphServiceImpl graphService = new GraphServiceImpl();
		graphService.setPath(graph);
		graphService.startup();
		ps = new RetryingPathServiceImpl(graphService,
				new EarliestArrivalSPTService());

		// read taxi files
		log.info("Reading taxi files from '" + taxilog + "'.");
		Collection<File> files = FileUtils.listFiles(new File(taxilog),
				new SuffixFileFilter(".csv.zip"), TrueFileFilter.INSTANCE);
		for (File f : files) {
			log.info("Reading '" + f + "'.");
			try {
				ZipInputStream z = new ZipInputStream(new FileInputStream(f));
				z.getNextEntry(); // ZIP files have many entries. In this case,
									// only one
				BufferedReader r = new BufferedReader(new InputStreamReader(z));
				r.readLine(); // header
				String line = null;
				while ((line = r.readLine()) != null) {
					RouteLogEntry rle = new RouteLogEntry(line);
					if (!rle.hasGeo()) {
						continue;
					}
					while (taskQueue.remainingCapacity() < 1) {
						Thread.sleep(100);
					}
					ex.submit(new RouteTask(rle));
				}
				r.close();
				z.close();
			} catch (Exception e) {
				log.error("Failed to read taxi file from '" + taxilog + "'.", e);
			}
		}
		ex.shutdown();
		try {
			ex.awaitTermination(Integer.MAX_VALUE, TimeUnit.DAYS);
		} catch (InterruptedException e) {
			// ...
		}
		log.info(deliveries);
	}

	private class RouteTask implements Runnable {
		private RouteLogEntry rle = null;

		public RouteTask(RouteLogEntry rle) {
			this.rle = rle;
		}

		@Override
		public void run() {
			List<GraphPath> paths = ps.getPaths(rle.toRoutingRequest());
			if (paths.size() != 1) {
				return;
			}
			deliver(new RouteTaskResult(rle, paths.get(0)));
		}
	}

	private static class RouteTaskResult {
		private RouteLogEntry rle;
		private GraphPath gp;

		public RouteTaskResult(RouteLogEntry rle, GraphPath gp) {
			this.rle = rle;
			this.gp = gp;
		}

		public RouteLogEntry getRouteLogEntry() {
			return rle;
		}

		public GraphPath getGraphPath() {
			return gp;
		}
	}

	// command line argument handling
	public static void main(String[] args) throws JSAPException {
		JSAP jsap = new JSAP();

		jsap.registerParameter(new FlaggedOption("graph").setShortFlag('g')
				.setLongFlag("graph").setStringParser(JSAP.STRING_PARSER)
				.setRequired(true).setHelp("OTP Graph"));

		jsap.registerParameter(new FlaggedOption("taxilog").setShortFlag('t')
				.setLongFlag("taxilog").setStringParser(JSAP.STRING_PARSER)
				.setRequired(true).setHelp("NY Taxi Log"));

		JSAPResult res = jsap.parse(args);

		if (!res.success()) {
			@SuppressWarnings("rawtypes")
			Iterator errs = res.getErrorMessageIterator();
			while (errs.hasNext()) {
				System.err.println(errs.next());
			}
			System.err.println("Usage: " + jsap.getUsage() + "\nParameters: "
					+ jsap.getHelp());
			System.exit(-1);
		}
		new TaxiRoute(res.getString("graph"), res.getString("taxilog")).start();
	}

	public synchronized void deliver(RouteTaskResult rtr) {
		System.out.println(rtr.getRouteLogEntry().getTripDistanceMeters()
				+ "\t" + rtr.getRouteLogEntry().getDistanceCrowfliesMeters()
				+ "\t" + rtr.getRouteLogEntry().getPickupWeekday() + "\t"
				+ rtr.getRouteLogEntry().getPickupHourOfDay() + "\t"
				+ rtr.getRouteLogEntry().getTripTimeInSecs() + "\t"
				+ rtr.getGraphPath().getDuration()
		// + "\t" + rtr.getDistanceRouteMeters()
				);
		deliveries++;
	}
}
