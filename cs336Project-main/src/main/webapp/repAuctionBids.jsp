<%@ page import="jakarta.servlet.http.*,java.sql.*,java.math.BigDecimal,com.cs336.pkg.ApplicationDB"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" %>

<%
    // Require login
    if (session == null || session.getAttribute("email") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String role = (String) session.getAttribute("role");
    if (role == null || !role.equalsIgnoreCase("CustomerRepresentative")) {
        // Only customer reps should access this page
        response.sendRedirect("home.jsp");
        return;
    }

    String auctionIdParam = request.getParameter("auctionId");
    if (auctionIdParam == null) {
        out.println("<h3 style='color:red;'>No auction selected.</h3>");
        return;
    }

    int auctionId = Integer.parseInt(auctionIdParam);

    ApplicationDB db = new ApplicationDB();
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
%>

<!DOCTYPE html>
<html>
<head>
    <title>Rep – Auction Details & Bids</title>
    <style>
        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background-color: #f9f9f9;
        }

        main {
            padding: 1.5rem;
        }

        /* Two-column layout */
        .container {
            display: flex;
            gap: 2rem;
            align-items: flex-start;
        }

        .left-column {
            flex: 1;
            max-width: 450px;
        }

        .right-column {
            flex: 1.5;
        }

        h2 {
            margin-top: 0;
        }

        /* Auction Details Box */
        .auction-details {
            padding: 1rem;
            border: 1px solid #ddd;
            border-radius: 6px;
            background-color: #fff;
        }

        .auction-details dt {
            font-weight: bold;
        }

        .auction-details dd {
            margin: 0 0 0.5rem 0;
        }

        /* Bid History Table */
        table {
            border-collapse: collapse;
            width: 100%;
            background-color: #fff;
            border-radius: 6px;
            overflow: hidden;
        }

        th, td {
            border: 1px solid #eee;
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

        .back-link {
            display: inline-block;
            margin-top: 1.5rem;
            text-decoration: none;
            color: #0073e6;
            font-size: 1rem;
        }
        .back-link:hover {
            text-decoration: underline;
        }

        .user-link {
            color: #0073e6;
            text-decoration: none;
        }
        .user-link:hover {
            text-decoration: underline;
        }

        .remove-button {
            padding: 4px 8px;
            font-size: 0.85rem;
            border-radius: 4px;
            border: 1px solid #c0392b;
            background-color: #e74c3c;
            color: #fff;
            cursor: pointer;
        }
        .remove-button:hover {
            background-color: #c0392b;
        }
    </style>
</head>
<body>

    <!-- Rep navbar -->
    <jsp:include page="customerRepNavbar.jsp" />

    <main>
        <h2>Rep – Auction Details & Bid Management</h2>

        <div class="container">

            <!-- LEFT COLUMN: Auction Details -->
            <div class="left-column">
                <%
                    try {
                        conn = db.getConnection();

                        // Load auction + item + seller info
                        String sqlInfo =
                            "SELECT a.auction_id, a.status, a.start_price, a.bid_increment, a.minimum_price, " +
                            "       a.start_time, a.end_time, a.winner_id, a.final_price, " +
                            "       a.user_id AS seller_id, " +
                            "       i.name AS item_name, " +
                            "       c.name AS category_name, " +
                            "       s.name AS subcategory_name " +
                            "  FROM Auctions a " +
                            "  JOIN Items i ON a.item_id = i.item_id " +
                            "  JOIN Category c ON i.category_id = c.category_id " +
                            "  JOIN Subcategory s " +
                            "    ON i.category_id = s.category_id " +
                            "   AND i.subcategory_id = s.subcategory_id " +
                            " WHERE a.auction_id = ?";

                        ps = conn.prepareStatement(sqlInfo);
                        ps.setInt(1, auctionId);
                        rs = ps.executeQuery();

                        if (!rs.next()) {
                %>
                            <p style="color:red;">Auction not found.</p>
                <%
                        } else {
                            String itemName    = rs.getString("item_name");
                            String catName     = rs.getString("category_name");
                            String subName     = rs.getString("subcategory_name");
                            String status      = rs.getString("status");

                            BigDecimal startPrice   = rs.getBigDecimal("start_price");
                            BigDecimal bidIncrement = rs.getBigDecimal("bid_increment");
                            BigDecimal minPrice     = rs.getBigDecimal("minimum_price");
                            BigDecimal finalPrice   = rs.getBigDecimal("final_price");

                            Timestamp startTime = rs.getTimestamp("start_time");
                            Timestamp endTime   = rs.getTimestamp("end_time");
                            int winnerId        = rs.getInt("winner_id");
                            boolean winnerNull  = rs.wasNull();
                            int sellerId        = rs.getInt("seller_id");

                            // Look up seller
                            String sellerName = "User ID " + sellerId;
                            String sellerEmail = "";
                            try (PreparedStatement psSeller = conn.prepareStatement(
                                     "SELECT first_name, last_name, email FROM Users WHERE user_id = ?")) {
                                psSeller.setInt(1, sellerId);
                                try (ResultSet rsSeller = psSeller.executeQuery()) {
                                    if (rsSeller.next()) {
                                        sellerName = rsSeller.getString("first_name") + " " +
                                                     rsSeller.getString("last_name");
                                        sellerEmail = rsSeller.getString("email");
                                    }
                                }
                            }
                %>

                <div class="auction-details">
                    <dl>
                        <dt>Auction ID</dt>
                        <dd><%= auctionId %></dd>

                        <dt>Item</dt>
                        <dd><%= itemName %></dd>

                        <dt>Category / Subcategory</dt>
                        <dd><%= catName %> / <%= subName %></dd>

                        <dt>Seller</dt>
                        <dd>
                            <a class="user-link" href="userProfile.jsp?userId=<%= sellerId %>">
                                <%= sellerName %>
                            </a>
                            <% if (sellerEmail != null && !sellerEmail.isEmpty()) { %>
                                (<%= sellerEmail %>)
                            <% } %>
                        </dd>

                        <dt>Status</dt>
                        <dd><%= status %></dd>

                        <dt>Start Price</dt>
                        <dd>$<%= startPrice %></dd>

                        <dt>Bid Increment</dt>
                        <dd>$<%= bidIncrement %></dd>

                        <dt>Minimum (Reserve) Price</dt>
                        <dd>$<%= minPrice %></dd>

                        <dt>Start Time</dt>
                        <dd><%= startTime %></dd>

                        <dt>End Time</dt>
                        <dd><%= endTime %></dd>

                        <dt>Final Price</dt>
                        <dd><%= (finalPrice != null ? "$" + finalPrice : "—") %></dd>

                        <dt>Winner</dt>
                        <dd>
                            <%
                                if (winnerNull) {
                                    out.print("None (no winner / reserve not met)");
                                } else {
                                    // Look up winner name/email
                                    String wName = "User ID " + winnerId;
                                    String wEmail = "";
                                    try (PreparedStatement psW = conn.prepareStatement(
                                             "SELECT first_name, last_name, email FROM Users WHERE user_id = ?")) {
                                        psW.setInt(1, winnerId);
                                        try (ResultSet rsW = psW.executeQuery()) {
                                            if (rsW.next()) {
                                                wName = rsW.getString("first_name") + " " +
                                                        rsW.getString("last_name");
                                                wEmail = rsW.getString("email");
                                            }
                                        }
                                    }
                            %>
                                    <a class="user-link" href="userProfile.jsp?userId=<%= winnerId %>">
                                        <%= wName %>
                                    </a>
                                    <% if (wEmail != null && !wEmail.isEmpty()) { %>
                                        (<%= wEmail %>)
                                    <% } %>
                            <%
                                }
                            %>
                        </dd>
                    </dl>
                </div>
            </div> <!-- END LEFT COLUMN -->

            <!-- RIGHT COLUMN: Bid history with REMOVE functionality -->
            <div class="right-column">
                <h3>Bid History (Remove Bids)</h3>

                <%
                        rs.close();
                        ps.close();

                        String sqlBids =
                            "SELECT b.bid_id, b.amount, b.placed_time, u.user_id, u.first_name, u.last_name " +
                            "  FROM Bids b " +
                            "  JOIN Users u ON b.bidder_id = u.user_id " +
                            " WHERE b.auction_id = ? " +
                            " ORDER BY b.placed_time DESC, b.bid_id DESC";

                        ps = conn.prepareStatement(sqlBids);
                        ps.setInt(1, auctionId);
                        rs = ps.executeQuery();

                        if (!rs.isBeforeFirst()) {
                %>
                            <p class="no-bids">No bids have been placed for this auction.</p>
                <%
                        } else {
                %>
                <table>
                    <thead>
                        <tr>
                            <th>Amount ($)</th>
                            <th>Time</th>
                            <th>Bidder</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        while (rs.next()) {
                            int bidId         = rs.getInt("bid_id");
                            BigDecimal amount = rs.getBigDecimal("amount");
                            Timestamp placed  = rs.getTimestamp("placed_time");
                            int bidderId      = rs.getInt("user_id");
                            String bFirst     = rs.getString("first_name");
                            String bLast      = rs.getString("last_name");
                    %>
                        <tr>
                            <td><%= amount %></td>
                            <td><%= placed %></td>
                            <td>
                                <a class="user-link" href="userProfile.jsp?userId=<%= bidderId %>">
                                    <%= bFirst %> <%= bLast %>
                                </a>
                            </td>
                            <td>
                                <!-- REMOVE BID FORM
                                     If your previous working version used a different servlet/URL or param names,
                                     just change "RepDeleteBidServlet" and/or the hidden field names to match. -->
                                <form action="RepDeleteBidServlet" method="post" style="display:inline;"
                                      onsubmit="return confirm('Are you sure you want to remove this bid?');">
                                    <input type="hidden" name="bid_id" value="<%= bidId %>">
                                    <input type="hidden" name="auction_id" value="<%= auctionId %>">
                                    <button type="submit" class="remove-button">Remove</button>
                                </form>
                            </td>
                        </tr>
                    <%
                        }
                    %>
                    </tbody>
                </table>
                <%
                        } // end bid results
                    } // end auction found
                } catch (Exception e) {
                    out.println("<p style='color:red;'>Error loading auction: " + e.getMessage() + "</p>");
                    e.printStackTrace();
                } finally {
                    if (rs   != null) try { rs.close(); } catch (Exception ignore) {}
                    if (ps   != null) try { ps.close(); } catch (Exception ignore) {}
                    if (conn != null) try { conn.close(); } catch (Exception ignore) {}
                }
                %>
            </div> <!-- END RIGHT COLUMN -->

        </div> <!-- END container -->

        <a href="repAuctionList.jsp" class="back-link">&larr; Back to Auctions List</a>
    </main>
</body>
</html>
