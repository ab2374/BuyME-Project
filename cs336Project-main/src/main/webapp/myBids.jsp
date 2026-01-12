<%@ page import="jakarta.servlet.http.*,java.sql.*,java.math.BigDecimal,com.cs336.pkg.ApplicationDB"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"%>

<%
    // Require login
    if (session == null || session.getAttribute("email") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Integer userId = (Integer) session.getAttribute("user_id");
    String firstName = (String) session.getAttribute("first_name");
    String lastName  = (String) session.getAttribute("last_name");

    if (userId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    ApplicationDB db = new ApplicationDB();
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
%>

<!DOCTYPE html>
<html>
<head>
    <title>My Bids</title>

    <style>
        body {
            margin: 0;
            font-family: Arial, sans-serif;
        }

        main {
            padding: 1.5rem;
        }

        h2 {
            margin-bottom: 0.5rem;
        }

        .subtitle {
            color: #555;
            margin-bottom: 1rem;
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

        .no-bids {
            margin-top: 1rem;
            font-style: italic;
        }

        .status-leading {
            color: green;
            font-weight: bold;
        }

        .status-outbid {
            color: #c0392b;
            font-weight: bold;
        }

        .status-won {
            color: #27ae60;
            font-weight: bold;
        }

        .status-lost {
            color: #7f8c8d;
            font-weight: bold;
        }

        .status-none {
            color: #555;
        }

        .view-link {
            text-decoration: none;
            color: #0073e6;
        }

        .view-link:hover {
            text-decoration: underline;
        }
    </style>
</head>

<body>

    <!-- Shared navbar -->
    <jsp:include page="navbar.jsp" />

    <main>
        <h2>My Bids</h2>
        <div class="subtitle">
            Bids placed by <strong><%= firstName %> <%= lastName %></strong>.
        </div>

        <%
            try {
                conn = db.getConnection();

                // One row per auction the user has bid on:
                // - user_max_bid: user's highest bid on that auction
                // - highest_bid: highest bid overall on that auction
                String sql =
                    "SELECT a.auction_id, a.status, a.end_time, a.winner_id, " +
                    "       i.name AS item_name, " +
                    "       c.name AS category_name, " +
                    "       s.name AS subcategory_name, " +
                    "       MAX(b.amount) AS user_max_bid, " +
                    "       (SELECT MAX(b2.amount) FROM Bids b2 WHERE b2.auction_id = a.auction_id) AS highest_bid " +
                    "FROM Bids b " +
                    "JOIN Auctions a ON b.auction_id = a.auction_id " +
                    "JOIN Items i ON a.item_id = i.item_id " +
                    "JOIN Category c ON i.category_id = c.category_id " +
                    "JOIN Subcategory s " +
                    "   ON i.category_id = s.category_id " +
                    "  AND i.subcategory_id = s.subcategory_id " +
                    "WHERE b.bidder_id = ? " +
                    "GROUP BY a.auction_id, a.status, a.end_time, a.winner_id, " +
                    "         i.name, c.name, s.name " +
                    "ORDER BY a.end_time DESC";

                ps = conn.prepareStatement(sql);
                ps.setInt(1, userId);
                rs = ps.executeQuery();

                if (!rs.isBeforeFirst()) {
        %>
                    <p class="no-bids">You haven't placed any bids yet.</p>
        <%
                } else {
        %>

        <table>
            <thead>
                <tr>
                    <th>Auction ID</th>
                    <th>Item</th>
                    <th>Category</th>
                    <th>Subcategory</th>
                    <th>Your Highest Bid ($)</th>
                    <th>Current Highest Bid ($)</th>
                    <th>Auction Status</th>
                    <th>Your Result</th>
                    <th>End Time</th>
                    <th>Edit Bid</th>
                    <th>View Bid History</th>
                </tr>
            </thead>
            <tbody>
        <%
                    while (rs.next()) {
                        int auctionId = rs.getInt("auction_id");
                        String itemName   = rs.getString("item_name");
                        String catName    = rs.getString("category_name");
                        String subName    = rs.getString("subcategory_name");
                        String status     = rs.getString("status");
                        Timestamp endTime = rs.getTimestamp("end_time");

                        BigDecimal userMaxBid = rs.getBigDecimal("user_max_bid");
                        BigDecimal highestBid = rs.getBigDecimal("highest_bid");

                        int winnerId = rs.getInt("winner_id");
                        boolean winnerIsNull = rs.wasNull();

                        String userResultText;
                        String userResultClass;

                        if ("OPEN".equalsIgnoreCase(status)) {
                            if (highestBid != null && userMaxBid != null &&
                                userMaxBid.compareTo(highestBid) == 0) {
                                userResultText  = "LEADING";
                                userResultClass = "status-leading";
                            } else {
                                userResultText  = "OUTBID";
                                userResultClass = "status-outbid";
                            }
                        } else { // CLOSED or other
                            if (winnerIsNull || highestBid == null) {
                                userResultText  = "NO WINNER";
                                userResultClass = "status-none";
                            } else if (!winnerIsNull && winnerId == userId) {
                                userResultText  = "WON";
                                userResultClass = "status-won";
                            } else {
                                userResultText  = "LOST";
                                userResultClass = "status-lost";
                            }
                        }
        %>
                <tr>
                    <td><%= auctionId %></td>
                    <td><%= itemName %></td>
                    <td><%= catName %></td>
                    <td><%= subName %></td>
                    <td><%= (userMaxBid != null ? userMaxBid.toPlainString() : "—") %></td>
                    <td><%= (highestBid != null ? highestBid.toPlainString() : "—") %></td>
                    <td><%= status %></td>
                    <td class="<%= userResultClass %>"><%= userResultText %></td>
                    <td><%= endTime %></td>
                    <td>
                        <!-- Edit bid: go to placeBid.jsp for this auction -->
                        <a href="placeBid.jsp?auctionId=<%= auctionId %>" class="view-link">
                            Edit Bid
                        </a>
                    </td>
                    <td>
                        <!-- View bid history: link to auction details + bid history page -->
                        <a href="viewAuction.jsp?auctionId=<%= auctionId %>" class="view-link">
                            View Bid History
                        </a>
                    </td>
                </tr>
        <%
                    } // while
        %>
            </tbody>
        </table>

        <%
                } // else
            } catch (Exception e) {
                out.println("<p style='color:red;'>Error loading your bids: " + e.getMessage() + "</p>");
                e.printStackTrace();
            } finally {
                if (rs != null) try { rs.close(); } catch (Exception ignore) {}
                if (ps != null) try { ps.close(); } catch (Exception ignore) {}
                if (conn != null) try { conn.close(); } catch (Exception ignore) {}
            }
        %>

    </main>
</body>
</html>
