<%@ page import="jakarta.servlet.http.*,java.sql.*,com.cs336.pkg.ApplicationDB" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%
    // Require login
    if (session == null || session.getAttribute("email") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Integer userId = (Integer) session.getAttribute("user_id");
    if (userId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    ApplicationDB db = new ApplicationDB();
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    int rowCount = 0;

    try {
        conn = db.getConnection();

        String sql =
            "SELECT a.auction_id, " +
            "       i.name          AS item_name, " +
            "       c.name          AS category_name, " +
            "       s.name          AS subcategory_name, " +
            "       a.start_price, " +
            "       a.bid_increment, " +
            "       a.minimum_price, " +
            "       a.start_time, " +
            "       a.end_time, " +
            "       a.status, " +
            "       (SELECT MAX(b.amount) " +
            "          FROM Bids b " +
            "         WHERE b.auction_id = a.auction_id) AS highest_bid " +
            "  FROM Auctions a " +
            "  JOIN Items i " +
            "    ON a.item_id = i.item_id " +
            "  JOIN Category c " +
            "    ON i.category_id = c.category_id " +
            "  JOIN Subcategory s " +
            "    ON i.category_id = s.category_id " +
            "   AND i.subcategory_id = s.subcategory_id " +
            " WHERE a.user_id = ? " +
            " ORDER BY a.start_time DESC";

        ps = conn.prepareStatement(sql);
        ps.setInt(1, userId);
        rs = ps.executeQuery();

%>
<!DOCTYPE html>
<html>
<head>
    <title>My Auctions</title>
    <style>
        body {
            margin: 0;
            font-family: Arial, sans-serif;
        }

        main {
            padding: 1.5rem;
        }

        h2 {
            margin-top: 0;
        }

        table {
            border-collapse: collapse;
            width: 100%;
            margin-top: 1rem;
        }

        th, td {
            border: 1px solid #ddd;
            padding: 8px 10px;
            text-align: left;
            font-size: 0.9rem;
        }

        th {
            background-color: #f5f5f5;
        }

        tr:nth-child(even) {
            background-color: #fafafa;
        }

        .status-open {
            color: green;
            font-weight: bold;
        }

        .status-closed {
            color: #b00;
            font-weight: bold;
        }

        .no-auctions {
            margin-top: 1rem;
            font-style: italic;
        }

        .view-link {
            text-decoration: none;
            color: #0073e6;
            font-size: 0.85rem;
        }

        .view-link:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>

    <!-- shared navbar -->
    <jsp:include page="navbar.jsp" />

    <main>
        <h2>My Auctions</h2>

        <%
            if (!rs.isBeforeFirst()) {
        %>
            <p class="no-auctions">You have not created any auctions yet.</p>
        <%
            } else {
        %>

        <table>
            <thead>
                <tr>
                    <th>Auction ID</th>
                    <th>Item Name</th>
                    <th>Category</th>
                    <th>Subcategory</th>
                    <th>Start Price ($)</th>
                    <th>Highest Bid ($)</th>
                    <th>Minimum Price ($)</th>
                    <th>Start Time</th>
                    <th>End Time</th>
                    <th>Status</th>
                    <th>View Bids</th>
                </tr>
            </thead>
            <tbody>
                <%
                    while (rs.next()) {
                        rowCount++;
                        int auctionId      = rs.getInt("auction_id");
                        String itemName    = rs.getString("item_name");
                        String catName     = rs.getString("category_name");
                        String subName     = rs.getString("subcategory_name");
                        java.math.BigDecimal startPrice  = rs.getBigDecimal("start_price");
                        java.math.BigDecimal highestBid  = rs.getBigDecimal("highest_bid");
                        java.math.BigDecimal minPrice    = rs.getBigDecimal("minimum_price");
                        Timestamp startTime = rs.getTimestamp("start_time");
                        Timestamp endTime   = rs.getTimestamp("end_time");
                        String status       = rs.getString("status");

                        String statusClass =
                            "OPEN".equalsIgnoreCase(status) ? "status-open" : "status-closed";
                %>
                <tr>
                    <td><%= auctionId %></td>
                    <td><%= itemName %></td>
                    <td><%= catName %></td>
                    <td><%= subName %></td>
                    <td><%= (startPrice != null ? startPrice.toPlainString() : "") %></td>
                    <td><%= (highestBid != null ? highestBid.toPlainString() : "—") %></td>
                    <td><%= (minPrice != null ? minPrice.toPlainString() : "") %></td>
                    <td><%= (startTime != null ? startTime.toString() : "") %></td>
                    <td><%= (endTime   != null ? endTime.toString()   : "") %></td>
                    <td class="<%= statusClass %>"><%= status %></td>
                    <td>
                        <a href="viewAuction.jsp?auctionId=<%= auctionId %>" class="view-link">
                            View Details / Bids
                        </a>
                    </td>
                </tr>
                <%
                    } // end while
                %>
            </tbody>
        </table>

        <%
            } // end else has rows
        %>

    </main>
</body>
</html>

<%
    } finally {
        if (rs   != null) try { rs.close(); } catch (Exception ignore) {}
        if (ps   != null) try { ps.close(); } catch (Exception ignore) {}
        if (conn != null) try { conn.close(); } catch (Exception ignore) {}
    }
%>
