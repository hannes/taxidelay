package org.muehleisen.hannes.taxiapp;

import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.Map;

import org.opentripplanner.common.geometry.DistanceLibrary;
import org.opentripplanner.common.geometry.SphericalDistanceLibrary;
import org.opentripplanner.routing.core.OptimizeType;
import org.opentripplanner.routing.core.RoutingRequest;
import org.opentripplanner.routing.core.TraverseMode;

public class RouteLogEntry {
	/**
	 * medallion,hack_license,vendor_id,rate_code,store_and_fwd_flag,
	 * pickup_datetime,dropoff_datetime,passenger_count,
	 * trip_time_in_secs,trip_distance,pickup_longitude,
	 * pickup_latitude,dropoff_longitude,dropoff_latitude
	 */

	private static Calendar cr = GregorianCalendar.getInstance();
	private static SimpleDateFormat df = new SimpleDateFormat(
			"yyyy-MM-dd HH:mm:ss");
	private static DistanceLibrary distanceLibrary = SphericalDistanceLibrary
			.getInstance();

	private String[] fields = null;

	public RouteLogEntry(String line) {
		this.fields = line.split(",");
	}

	public RoutingRequest toRoutingRequest() {
		RoutingRequest rq = new RoutingRequest();
		rq.setFromString("f::" + getPickupLatitude() + ","
				+ getPickupLongitude());
		rq.setToString("t::" + getDropoffLatitude() + ","
				+ getDropoffLongitude());
		rq.setMode(TraverseMode.CAR);
		rq.setOptimize(OptimizeType.QUICK);
		return rq;
	}

	public boolean hasGeo() {
		return !"0".equals(fields[10]);
	}

	public Date getPickupDatetime() {
		try {
			return df.parse(fields[5]);
		} catch (ParseException e) {
			// uah
		}
		return Calendar.getInstance().getTime();
	}

	public int getTripTimeInSecs() {
		return Integer.parseInt(fields[8]);
	}

	public int getPickupHourOfDay() {
		cr.setTime(getPickupDatetime());
		return cr.get(Calendar.HOUR_OF_DAY);
	}

	public double getPickupLongitude() {
		return Double.parseDouble(fields[10]);
	}

	public double getPickupLatitude() {
		return Double.parseDouble(fields[11]);
	}

	public double getDropoffLongitude() {
		return Double.parseDouble(fields[12]);
	}

	public double getDropoffLatitude() {
		return Double.parseDouble(fields[13]);
	}

	public long getTripDistanceMeters() {
		return Math.round(Double.parseDouble(fields[9]) * 1609.34);
	}

	public long getDistanceCrowfliesMeters() {
		return Math.round(distanceLibrary.fastDistance(getPickupLatitude(),
				getPickupLongitude(), getDropoffLatitude(),
				getDropoffLongitude()));
	}

	public Object getPickupWeekday() {
		cr.setTime(getPickupDatetime());
		return cr.get(Calendar.DAY_OF_WEEK);
	}

	private static Map<String, String> lrt = new HashMap<String, String>();

	public static void initLrt() {
		MessageDigest md = null;
		try {
			md = MessageDigest.getInstance("MD5");
		} catch (NoSuchAlgorithmException e) {
			// md5 exists, shut pu
		}

		for (int i = 0; i < 1000000; i++) {
			String id1 = String.format("%06d", i);
			String id2 = "5" + id1;

			String h1 = new BigInteger(1, md.digest(id1.getBytes()))
					.toString(16).toUpperCase();
			String h2 = new BigInteger(1, md.digest(id2.getBytes()))
					.toString(16).toUpperCase();
			lrt.put(h1, id1);
			lrt.put(h2, id2);
		}
	}

	// http://www.theguardian.com/technology/2014/jun/27/new-york-taxi-details-anonymised-data-researchers-warn

	public String getLicense() {
		if (lrt.containsKey(fields[1])) {
			return lrt.get(fields[1]);
		} else {
			return fields[1];
		}
	}
}