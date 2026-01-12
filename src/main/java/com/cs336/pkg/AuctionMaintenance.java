package com.cs336.pkg;

import java.math.BigDecimal;
import java.sql.*;

/**
 * Utility class used by a scheduler / maintenance job
 * to close expired auctions.
 */
public class AuctionMaintenance {

    /**
     * Called by the Scheduler to close expired auctions.
     */
    public static void closeExpiredAuctions(Connection conn) throws Exception {

        // 1. Find all auctions that have passed end_time and are still OPEN
        String expiredSql =
            "SELECT auction_id FROM Auctions " +
            "WHERE status = 'OPEN' AND end_time <= NOW()";

        try (PreparedStatement ps = conn.prepareStatement(expiredSql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                int auctionId = rs.getInt("auction_id");
                closeSingleAuction(conn, auctionId);
            }
        }
    }

    /**
     * Closes a single auction:
     * - Finds highest bid
     * - Applies reserve price logic
     * - Sets winner + final_price (or none)
     * - Sends notifications to winner / seller
     */
    private static void closeSingleAuction(Connection conn, int auctionId) throws Exception {

        BigDecimal reserve = null;
        int sellerId = 0;

        // Get reserve price AND seller (user_id)
        String reserveSql =
            "SELECT minimum_price, user_id " +
            "FROM Auctions WHERE auction_id = ?";

        try (PreparedStatement ps = conn.prepareStatement(reserveSql)) {
            ps.setInt(1, auctionId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    reserve  = rs.getBigDecimal("minimum_price");
                    sellerId = rs.getInt("user_id");
                } else {
                    // Auction not found; nothing to do
                    System.out.println("Auction " + auctionId + " not found.");
                    return;
                }
            }
        }

        // Get highest bid
        Integer winnerId = null;
        BigDecimal finalPrice = null;

        String highestBidSql =
            "SELECT bidder_id, amount " +
            "FROM Bids WHERE auction_id = ? " +
            "ORDER BY amount DESC LIMIT 1";

        try (PreparedStatement ps = conn.prepareStatement(highestBidSql)) {
            ps.setInt(1, auctionId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    winnerId   = rs.getInt("bidder_id");
                    finalPrice = rs.getBigDecimal("amount");
                }
            }
        }

        // Apply reserve logic
        boolean reserveNotMet;

        if (winnerId == null) {
            // No bids at all
            reserveNotMet = true;
        } else if (reserve == null) {
            // No reserve set -> always met if we have a bid
            reserveNotMet = false;
        } else {
            reserveNotMet = (finalPrice.compareTo(reserve) < 0);
        }

        if (reserveNotMet) {
            winnerId   = null;
            finalPrice = null;
        }

        // Update auction to CLOSED
        String updateSql =
            "UPDATE Auctions " +
            "SET status = 'CLOSED', winner_id = ?, final_price = ? " +
            "WHERE auction_id = ?";

        try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
            if (winnerId == null) {
                ps.setNull(1, Types.INTEGER);
                ps.setNull(2, Types.DECIMAL);
            } else {
                ps.setInt(1, winnerId);
                ps.setBigDecimal(2, finalPrice);
            }
            ps.setInt(3, auctionId);
            ps.executeUpdate();
        }

        // ===== NOTIFICATIONS =====
        try {
            if (winnerId != null && finalPrice != null) {
                // Notify winner
            	String winMsg = "🎉 Congratulations! You won auction #" + auctionId +
            		    " with a final bid of $" + finalPrice.toPlainString() +
            		    "<br><a href=\"viewAuction.jsp?auctionId=" + auctionId + "\">View Auction Details</a>";

            		NotificationUtil.createNotification(winnerId, winMsg);


                // Notify seller that their item sold
                NotificationUtil.createNotification(
                    sellerId,
                    "Your auction #" + auctionId +
                    " has ended with a winning bid of $" + finalPrice.toPlainString()  +
        		    "<br><a href=\"viewAuction.jsp?auctionId=" + auctionId + "\">View Auction Details</a>"
                );
            } else {
                // No winner (reserve not met or no bids) – notify seller
                NotificationUtil.createNotification(
                    sellerId,
                    "Your auction #" + auctionId +
                    " has ended without a winning bid (reserve not met or no bids)."
                );
            }
        } catch (SQLException e) {
            // Don't let a notification failure break auction closing
            e.printStackTrace();
        }

        System.out.println("Auction " + auctionId + " closed.");
    }
}
