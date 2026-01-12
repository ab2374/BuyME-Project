package com.cs336.pkg;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.*;

@WebServlet("/AutobidServlet")
public class AutobidServlet extends HttpServlet {

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
        String maxAmountStr = request.getParameter("max_amount");
        String autoIncStr   = request.getParameter("auto_increment");
        String cancelFlag   = request.getParameter("cancel");   // "1" if stopping autobid

        if (auctionIdStr == null) {
            response.sendRedirect("home.jsp");
            return;
        }

        int auctionId = Integer.parseInt(auctionIdStr);

        ApplicationDB db = new ApplicationDB();
        Connection conn = null;

        try {
            conn = db.getConnection();
            conn.setAutoCommit(false);

            // If user clicked "Stop Auto-Bid", just delete their autobid
            if ("1".equals(cancelFlag)) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM Autobid WHERE user_id = ? AND auction_id = ?")) {
                    ps.setInt(1, userId);
                    ps.setInt(2, auctionId);
                    ps.executeUpdate();
                }

                conn.commit();
                response.sendRedirect("placeBid.jsp?auctionId=" + auctionId + "&autoBidStopped=1");
                return;
            }

            // From here on: creating/updating autobid → need max_amount and auto_increment
            if (maxAmountStr == null || autoIncStr == null) {
                conn.rollback();
                response.sendRedirect("placeBid.jsp?auctionId=" + auctionId + "&error=missingFields");
                return;
            }

            // 1) Load auction info + ensure OPEN + not seller
            String status;
            int sellerId;
            BigDecimal startPrice, auctionBidIncrement;
            Timestamp endTime;

            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT user_id AS seller_id, status, start_price, bid_increment, end_time " +
                    "FROM Auctions WHERE auction_id = ?")) {

                ps.setInt(1, auctionId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        conn.rollback();
                        response.sendRedirect("home.jsp?auctionNotFound=1");
                        return;
                    }
                    sellerId            = rs.getInt("seller_id");
                    status              = rs.getString("status");
                    startPrice          = rs.getBigDecimal("start_price");
                    auctionBidIncrement = rs.getBigDecimal("bid_increment");
                    endTime             = rs.getTimestamp("end_time");
                }
            }

            if (sellerId == userId) {
                conn.rollback();
                response.sendRedirect("home.jsp?cannotAutoBidOnOwnAuction=1");
                return;
            }

            if (!"OPEN".equalsIgnoreCase(status)
                    || endTime.before(new Timestamp(System.currentTimeMillis()))) {
                conn.rollback();
                response.sendRedirect("home.jsp?auctionClosed=1");
                return;
            }

            // 2) Current highest bid → to compute minNextBid
            BigDecimal highestBid = null;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT MAX(amount) AS max_amount FROM Bids WHERE auction_id = ?")) {
                ps.setInt(1, auctionId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        highestBid = rs.getBigDecimal("max_amount");
                    }
                }
            }

            BigDecimal minNextBid;
            if (highestBid == null) {
                minNextBid = startPrice;
            } else {
                minNextBid = highestBid.add(auctionBidIncrement);
            }

            // 3) Parse and validate max_amount
            BigDecimal maxAmount;
            try {
                maxAmount = new BigDecimal(maxAmountStr);
            } catch (NumberFormatException e) {
                conn.rollback();
                response.sendRedirect("placeBid.jsp?auctionId=" + auctionId + "&error=badMax");
                return;
            }

            if (maxAmount.compareTo(minNextBid) < 0) {
                conn.rollback();
                response.sendRedirect("placeBid.jsp?auctionId=" + auctionId + "&error=maxTooLow");
                return;
            }

            // 4) Parse and validate auto_increment (must be ≥ auction's bid_increment)
            BigDecimal autoIncrement;
            try {
                autoIncrement = new BigDecimal(autoIncStr);
            } catch (NumberFormatException e) {
                conn.rollback();
                response.sendRedirect("placeBid.jsp?auctionId=" + auctionId + "&error=badIncrement");
                return;
            }

            if (autoIncrement.compareTo(auctionBidIncrement) < 0
                    || autoIncrement.compareTo(BigDecimal.ZERO) <= 0) {
                conn.rollback();
                response.sendRedirect("placeBid.jsp?auctionId=" + auctionId + "&error=incTooLow");
                return;
            }

            // 5) Upsert into Autobid: if an active record exists for this user+auction, update it
            Integer existingId = null;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT autobid_id FROM Autobid WHERE user_id = ? AND auction_id = ?")) {
                ps.setInt(1, userId);
                ps.setInt(2, auctionId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        existingId = rs.getInt("autobid_id");
                    }
                }
            }

            if (existingId == null) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO Autobid " +
                        "(user_id, auction_id, max_amount, increment, active, created_time) " +
                        "VALUES (?, ?, ?, ?, 1, NOW())")) {
                    ps.setInt(1, userId);
                    ps.setInt(2, auctionId);
                    ps.setBigDecimal(3, maxAmount);
                    ps.setBigDecimal(4, autoIncrement);
                    ps.executeUpdate();
                }
            } else {
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE Autobid " +
                        "SET max_amount = ?, increment = ?, active = 1, created_time = NOW() " +
                        "WHERE autobid_id = ?")) {
                    ps.setBigDecimal(1, maxAmount);
                    ps.setBigDecimal(2, autoIncrement);
                    ps.setInt(3, existingId);
                    ps.executeUpdate();
                }
            }

            // 6) Run automatic bidding logic (this should now use the increment column)
            AuctionAutoBidUtil.runAutoBidding(conn, auctionId);

            conn.commit();

            response.sendRedirect("placeBid.jsp?auctionId=" + auctionId + "&autoBidSet=1");

        } catch (Exception e) {
            e.printStackTrace();
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ignore) {}
            }
            response.sendRedirect("placeBid.jsp?auctionId=" + auctionId + "&error=internal");
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); } catch (SQLException ignore) {}
            }
        }
    }
}
