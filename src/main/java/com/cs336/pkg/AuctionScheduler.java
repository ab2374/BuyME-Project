package com.cs336.pkg;

import java.sql.Connection;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

public class AuctionScheduler {

    private static ScheduledExecutorService executor;

    public static void start() {
        if (executor != null) return; // already running

        executor = Executors.newSingleThreadScheduledExecutor();

        executor.scheduleAtFixedRate(() -> {
            try {
                // Get DB connection
                ApplicationDB db = new ApplicationDB();
                Connection conn = db.getConnection();

                System.out.println("AuctionScheduler: Checking expired auctions...");

                AuctionMaintenance.closeExpiredAuctions(conn);

                conn.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }, 0, 30, TimeUnit.SECONDS);  // runs EVERY 30 seconds
    }

    public static void stop() {
        if (executor != null) {
            executor.shutdownNow();
        }
    }
}
