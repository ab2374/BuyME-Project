package com.cs336.pkg;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.*;

// Auto-bid utility
import com.cs336.pkg.AuctionAutoBidUtil;
// Notifications
import com.cs336.pkg.NotificationUtil;

@WebServlet("/PlaceBidServlet")
public class PlaceBidServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int userId = (Integer) session.getAttribute("user_id");
        String auctionIdStr = request.getParameter("auction_id");
        String bidAmountStr = request.getParameter("bid_amount");

        if (auctionIdStr == null || bidAmountStr == null) {
            response.sendRedirect("home.jsp");
            return;
        }

        int auctionId = Integer.parseInt(auctionIdStr);
        BigDecimal bidAmount = new BigDecimal(bidAmountStr);

        ApplicationDB db = new ApplicationDB();

        // We'll fill these and use them AFTER commit for notifications
        Integer prevHighestBidderId = null;
        BigDecimal prevHighestAmount = null;
        int sellerId = -1;

        try (Connection conn = db.getConnection()) {
            conn.setAutoCommit(false);

            // 1) Load auction info
            String auctionSql =
                "SELECT status, end_time, start_price, bid_increment, user_id AS seller_id " +
                "FROM Auctions WHERE auction_id = ?";

            String status;
            Timestamp endTime;
            BigDecimal startPrice;
            BigDecimal bidIncrement;

            try (PreparedStatement ps = conn.prepareStatement(auctionSql)) {
                ps.setInt(1, auctionId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        conn.rollback();
                        response.sendRedirect("home.jsp?auctionNotFound=1");
                        return;
                    }
                    status       = rs.getString("status");
                    endTime      = rs.getTimestamp("end_time");
                    startPrice   = rs.getBigDecimal("start_price");
                    bidIncrement = rs.getBigDecimal("bid_increment");
                    sellerId     = rs.getInt("seller_id");
                }
            }

            // Seller cannot bid on own auction
            if (sellerId == userId) {
                conn.rollback();
                response.sendRedirect("home.jsp?cannotBidOnOwnAuction=1");
                return;
            }

            // 2) Check auction still OPEN and not past end time
            java.time.Instant now = java.time.Instant.now();
            if (!"OPEN".equalsIgnoreCase(status) || endTime.toInstant().isBefore(now)) {
                conn.rollback();
                response.sendRedirect("home.jsp?auctionClosed=1");
                return;
            }

            // 3) Get previous highest bid (bidder + amount) BEFORE inserting new bid
            BigDecimal highestBid = null;
            String prevHighestSql =
                "SELECT bidder_id, amount " +
                "FROM Bids " +
                "WHERE auction_id = ? " +
                "ORDER BY amount DESC, placed_time ASC " +
                "LIMIT 1";

            try (PreparedStatement psPrev = conn.prepareStatement(prevHighestSql)) {
                psPrev.setInt(1, auctionId);
                try (ResultSet rsPrev = psPrev.executeQuery()) {
                    if (rsPrev.next()) {
                        prevHighestBidderId = rsPrev.getInt("bidder_id");
                        prevHighestAmount   = rsPrev.getBigDecimal("amount");
                        highestBid          = prevHighestAmount;
                    }
                }
            }

            // 4) Compute minNextBid
            BigDecimal minNextBid;
            if (highestBid == null) {
                minNextBid = startPrice;
            } else {
                minNextBid = highestBid.add(bidIncrement);
            }

            // 5) Validate bid amount
            if (bidAmount.compareTo(minNextBid) < 0) {
                conn.rollback(); // rollback first
                request.setAttribute("error",
                    "Your bid must be at least $" + minNextBid.toPlainString());
                request.getRequestDispatcher("placeBid.jsp?auctionId=" + auctionId)
                       .forward(request, response);
                return;
            }

            // 6) Insert the manual bid
            String insertSql =
                "INSERT INTO Bids (auction_id, bidder_id, amount, placed_time) " +
                "VALUES (?, ?, ?, NOW())";
            try (PreparedStatement psIns = conn.prepareStatement(insertSql)) {
                psIns.setInt(1, auctionId);
                psIns.setInt(2, userId);
                psIns.setBigDecimal(3, bidAmount);
                psIns.executeUpdate();
            }

            // 7) Run automatic bidding for THIS auction before committing
            AuctionAutoBidUtil.runAutoBidding(conn, auctionId);

            // 8) Commit everything (manual bid + auto-bid chain)
            conn.commit();

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Error placing bid: " + e.getMessage());
            request.getRequestDispatcher("placeBid.jsp?auctionId=" + auctionIdStr)
                   .forward(request, response);
            return;
        }

        // 9) AFTER commit, send notifications (using a separate connection inside NotificationUtil)
        try {
            // 9a) Notify previous highest bidder that they were outbid
            if (prevHighestBidderId != null &&
                !prevHighestBidderId.equals(userId) &&
                prevHighestAmount != null &&
                bidAmount.compareTo(prevHighestAmount) > 0) {

                String outbidMsg =
                    "You have been outbid on auction #" + auctionId +
                    ". Your previous highest bid was $" + prevHighestAmount.toPlainString() +
                    ". The new bid is $" + bidAmount.toPlainString() + "." +
                    "<br><a href=\"placeBid.jsp?auctionId=" + auctionId +
                    "\">View auction and place a higher bid</a>";

                NotificationUtil.createNotification(prevHighestBidderId, outbidMsg);
            }

            // 9b) Notify seller that their auction received a new bid
            // (extra safety: don't notify if somehow sellerId == userId, though we already guarded)
            if (sellerId != -1 && sellerId != userId) {
                String sellerMsg =
                    "Your auction #" + auctionId +
                    " received a new bid of $" + bidAmount.toPlainString() + "." +
                    "<br><a href=\"viewAuction.jsp?auctionId=" + auctionId +
                    "\">View auction details</a>";

                NotificationUtil.createNotification(sellerId, sellerMsg);
            }

        } catch (Exception notifyEx) {
            // Don't break the user flow just because notifications failed
            notifyEx.printStackTrace();
        }

        // 10) Finally, redirect back to the bid page
        response.sendRedirect("placeBid.jsp?auctionId=" + auctionId + "&success=1");
    }
}
