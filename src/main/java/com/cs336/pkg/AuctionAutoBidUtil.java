package com.cs336.pkg;

import java.math.BigDecimal;
import java.sql.*;

// For creating notifications
import com.cs336.pkg.NotificationUtil;

/**
 * Utility for running automatic bidding on a single auction.
 *
 * Assumptions:
 * - Autobid table has: autobid_id (optional), user_id, auction_id, max_amount, increment, active, created_time
 * - Auctions table has: start_price, bid_increment, status, end_time
 * - Bids table: (auction_id, bidder_id, amount, placed_time)
 *
 * This method should be called inside an existing transaction (autoCommit=false)
 * from PlaceBidServlet and AutobidServlet after they insert/update data.
 */
public class AuctionAutoBidUtil {

    public static void runAutoBidding(Connection conn, int auctionId) throws SQLException {
        // 1. Load auction info and ensure it is OPEN and not ended
        String status;
        Timestamp endTime;
        BigDecimal startPrice;
        BigDecimal auctionBidIncrement;

        String auctionSql =
            "SELECT status, end_time, start_price, bid_increment " +
            "FROM Auctions WHERE auction_id = ?";

        try (PreparedStatement ps = conn.prepareStatement(auctionSql)) {
            ps.setInt(1, auctionId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    // Auction not found
                    return;
                }
                status              = rs.getString("status");
                endTime             = rs.getTimestamp("end_time");
                startPrice          = rs.getBigDecimal("start_price");
                auctionBidIncrement = rs.getBigDecimal("bid_increment");
            }
        }

        // Not open or already expired? Don’t auto-bid.
        if (!"OPEN".equalsIgnoreCase(status)) {
            return;
        }
        Timestamp now = new Timestamp(System.currentTimeMillis());
        if (endTime != null && endTime.before(now)) {
            return;
        }

        // 2. Loop: let autobidders fight it out until no one can outbid
        while (true) {
            // 2a. Get current highest bid (if any)
            Integer highestBidderId = null;
            BigDecimal highestBidAmount = null;

            String highestBidSql =
                "SELECT bidder_id, amount " +
                "FROM Bids " +
                "WHERE auction_id = ? " +
                "ORDER BY amount DESC, placed_time ASC " +
                "LIMIT 1";

            try (PreparedStatement ps = conn.prepareStatement(highestBidSql)) {
                ps.setInt(1, auctionId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        highestBidderId  = rs.getInt("bidder_id");
                        highestBidAmount = rs.getBigDecimal("amount");
                    }
                }
            }

            // 2b. Load all active autobids for this auction
            String autoSql =
                "SELECT autobid_id, user_id, max_amount, increment, created_time " +
                "FROM Autobid " +
                "WHERE auction_id = ? AND active = 1";

            Integer bestUserId = null;
            BigDecimal bestMaxAmount = null;
            BigDecimal bestIncrement = null;
            Timestamp bestCreatedTime = null;
            BigDecimal bestProposedBid = null;

            try (PreparedStatement ps = conn.prepareStatement(autoSql)) {
                ps.setInt(1, auctionId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        int userId         = rs.getInt("user_id");
                        BigDecimal maxAmt  = rs.getBigDecimal("max_amount");
                        BigDecimal inc     = rs.getBigDecimal("increment");
                        Timestamp created  = rs.getTimestamp("created_time");

                        if (maxAmt == null || inc == null) continue;

                        // Don't try to outbid yourself if you're currently the highest bidder
                        if (highestBidderId != null && userId == highestBidderId) {
                            continue;
                        }

                        // Compute this autobidder's proposed bid
                        BigDecimal proposed;
                        if (highestBidAmount == null) {
                            // No bids yet → first autobid can simply bid the start price
                            proposed = startPrice;
                        } else {
                            // There is a highest bid. We must at least beat:
                            // - highestBid + auctionBidIncrement  (global min increment)
                            // - highestBid + userIncrement        (user’s step)
                            BigDecimal requiredMin = highestBidAmount.add(auctionBidIncrement);
                            BigDecimal plusUserInc = highestBidAmount.add(inc);
                            proposed = requiredMin.max(plusUserInc);
                        }

                        // If proposed exceeds user's max, they cannot bid at this step
                        if (proposed.compareTo(maxAmt) > 0) {
                            continue;
                        }

                        // Among all autobidders, choose the one with the highest proposed bid.
                        // Tie-breaker: earliest created_time wins.
                        if (bestProposedBid == null ||
                            proposed.compareTo(bestProposedBid) > 0 ||
                            (proposed.compareTo(bestProposedBid) == 0 &&
                             created != null &&
                             (bestCreatedTime == null || created.before(bestCreatedTime)))) {

                            bestUserId       = userId;
                            bestMaxAmount    = maxAmt;
                            bestIncrement    = inc;
                            bestCreatedTime  = created;
                            bestProposedBid  = proposed;
                        }
                    }
                }
            }

            // 2c. No autobidder can place a valid higher bid → we are done
            if (bestUserId == null || bestProposedBid == null) {
                break;
            }

            // 2d. Insert the winning autobid for this "round"
            String insertBidSql =
                "INSERT INTO Bids (auction_id, bidder_id, amount, placed_time) " +
                "VALUES (?, ?, ?, NOW())";

            try (PreparedStatement ps = conn.prepareStatement(insertBidSql)) {
                ps.setInt(1, auctionId);
                ps.setInt(2, bestUserId);
                ps.setBigDecimal(3, bestProposedBid);
                ps.executeUpdate();
            }

            // Next loop iteration will consider this bid as the new highest bid and
            // see if any other autobidder can beat it.
        }

        // 3. After the auto-bidding dust settles, remove autobids that are now useless
        //    and notify their owners.
        deactivateAndNotifyFinishedAutobids(conn, auctionId);

        // Note: we do NOT close or commit the Connection here.
        // Caller (servlet) is responsible for committing/rolling back.
    }

    /**
     * After auto-bidding, find all active autobids whose max_amount is now below
     * the final highest bid, DELETE them, and notify the users.
     */
    private static void deactivateAndNotifyFinishedAutobids(Connection conn, int auctionId) throws SQLException {
        // 1) Get final highest bid amount
        BigDecimal finalHighest = null;

        String highestBidSql =
            "SELECT amount " +
            "FROM Bids " +
            "WHERE auction_id = ? " +
            "ORDER BY amount DESC, placed_time ASC " +
            "LIMIT 1";

        try (PreparedStatement ps = conn.prepareStatement(highestBidSql)) {
            ps.setInt(1, auctionId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    finalHighest = rs.getBigDecimal("amount");
                }
            }
        }

        if (finalHighest == null) {
            // No bids at all → nothing to deactivate
            return;
        }

        // 2) Find all active autobids whose max_amount < finalHighest
        String selectAuto =
            "SELECT user_id, max_amount " +
            "FROM Autobid " +
            "WHERE auction_id = ? AND active = 1 AND max_amount < ?";

        try (PreparedStatement ps = conn.prepareStatement(selectAuto)) {
            ps.setInt(1, auctionId);
            ps.setBigDecimal(2, finalHighest);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int userId = rs.getInt("user_id");
                    BigDecimal maxAmount = rs.getBigDecimal("max_amount");

                    // 3) DELETE this autobid (only if it's still active now)
                    int deleted;
                    try (PreparedStatement psDel = conn.prepareStatement(
                            "DELETE FROM Autobid " +
                            "WHERE auction_id = ? AND user_id = ? AND active = 1")) {
                        psDel.setInt(1, auctionId);
                        psDel.setInt(2, userId);
                        deleted = psDel.executeUpdate();
                    }

                    // If we actually deleted it from active state, send notification
                    if (deleted > 0) {
                        sendAutobidLimitNotification(userId, auctionId, maxAmount, finalHighest);
                    }
                }
            }
        }
    }

    /**
     * Notify a user that their automatic bidding hit their max and is no longer active.
     */
    private static void sendAutobidLimitNotification(
            int userId,
            int auctionId,
            BigDecimal maxAmount,
            BigDecimal currentHighest
    ) {
        try {
            String msg =
                "Your automatic bidding on auction #" + auctionId +
                " has reached your maximum of $" + maxAmount.toPlainString() +
                " and is no longer active. The current highest bid is $" +
                currentHighest.toPlainString() + "." +
                "<br><a href=\"placeBid.jsp?auctionId=" + auctionId + "\">" +
                "View this auction and place a manual bid</a>";

            NotificationUtil.createNotification(userId, msg);
        } catch (Exception e) {
            // Log but don't break the auction logic
            e.printStackTrace();
        }
    }
}
