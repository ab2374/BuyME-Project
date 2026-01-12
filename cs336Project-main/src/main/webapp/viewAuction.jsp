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
    if (userId == null) {
        response.sendRedirect("login.jsp");
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
    <title>Auction Details & Bids</title>
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

    <jsp:include page="navbar.jsp" />

    <main>
        <h2>Auction Overview</h2>

        <div class="container">

            <!-- LEFT COLUMN: Auction Details -->
            <div class="left-column">
                <%
                    try {
                        conn = db.getConnection();

                        String sqlInfo =
                            "SELECT a.auction_id, a.status, a.start_price, a.bid_increment, a.minimum_price, " +
                            "       a.start_time, a.end_time, a.winner_id, a.final_price, " +
                            "       i.item_id, i.name AS item_name, " +
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
                            int itemId       = rs.getInt("item_id");
                            String itemName  = rs.getString("item_name");
                            String catName   = rs.getString("category_name");
                            String subName   = rs.getString("subcategory_name");
                            String status    = rs.getString("status");

                            BigDecimal startPrice   = rs.getBigDecimal("start_price");
                            BigDecimal bidIncrement = rs.getBigDecimal("bid_increment");
                            BigDecimal minPrice     = rs.getBigDecimal("minimum_price");
                            BigDecimal finalPrice   = rs.getBigDecimal("final_price");

                            Timestamp startTime = rs.getTimestamp("start_time");
                            Timestamp endTime   = rs.getTimestamp("end_time");
                            int winnerId        = rs.getInt("winner_id");
                            boolean winnerNull  = rs.wasNull();
                %>

                <div class="auction-details">
                    <dl>
                        <dt>Auction ID</dt>
                        <dd><%= auctionId %></dd>

                        <dt>Item</dt>
                        <dd><%= itemName %></dd>

                        <dt>Category / Subcategory</dt>
                        <dd><%= catName %> / <%= subName %></dd>

                        <!-- Item details (dynamic fields) -->
                        <dt>Item Details</dt>
                        <dd>
                            <%
                                PreparedStatement psFields = null;
                                ResultSet rsFields = null;
                                try {
                                    psFields = conn.prepareStatement(
                                        "SELECT f.name, v.value " +
                                        "FROM ItemFieldValues v " +
                                        "JOIN Fields f ON v.field_id = f.field_id " +
                                        "WHERE v.item_id = ? " +
                                        "ORDER BY f.name"
                                    );
                                    psFields.setInt(1, itemId);
                                    rsFields = psFields.executeQuery();

                                    if (!rsFields.isBeforeFirst()) {
                            %>
                                        <span>None</span>
                            <%
                                    } else {
                            %>
                                        <ul style="padding-left: 1.2rem; margin: 0;">
                            <%
                                        while (rsFields.next()) {
                                            String fname = rsFields.getString("name");
                                            String fval  = rsFields.getString("value");
                            %>
                                            <li><strong><%= fname %>:</strong> <%= fval %></li>
                            <%
                                        }
                            %>
                                        </ul>
                            <%
                                    }
                                } catch (Exception e2) {
                                    out.println("<span style='color:red;'>Error loading item details: " + e2.getMessage() + "</span>");
                                    e2.printStackTrace();
                                } finally {
                                    if (rsFields != null) try { rsFields.close(); } catch (Exception ignore) {}
                                    if (psFields != null) try { psFields.close(); } catch (Exception ignore) {}
                                }
                            %>
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
                                    PreparedStatement psW = conn.prepareStatement(
                                        "SELECT first_name, last_name, email, user_id FROM Users WHERE user_id = ?"
                                    );
                                    psW.setInt(1, winnerId);
                                    ResultSet rsW = psW.executeQuery();
                                    if (rsW.next()) {
                                        int wId       = winnerId;
                                        String wFirst = rsW.getString("first_name");
                                        String wLast  = rsW.getString("last_name");
                                        String wEmail = rsW.getString("email");
                            %>
                                        <a class="auction-profile-link"
                                           href="userProfileAuctions.jsp?userId=<%= wId %>">
                                            <%= wFirst %> <%= wLast %>
                                        </a>
                                        (<%= wEmail %>)
                            <%
                                    } else {
                                        out.print("User ID " + winnerId);
                                    }
                                    rsW.close();
                                    psW.close();
                                }
                            %>
                        </dd>
                    </dl>
                </div>
            </div> <!-- END LEFT COLUMN -->

            <!-- RIGHT COLUMN: Bid history -->
            <div class="right-column">
                <h3>Bid History</h3>

                <%
                        rs.close();
                        ps.close();

                        String sqlBids =
                            "SELECT b.amount, b.placed_time, b.bidder_id, " +
                            "       u.first_name, u.last_name, u.isAnonymous " +
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
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        while (rs.next()) {
                            int bidderId      = rs.getInt("bidder_id");
                            BigDecimal amt    = rs.getBigDecimal("amount");
                            Timestamp placed  = rs.getTimestamp("placed_time");
                            String bf         = rs.getString("first_name");
                            String bl         = rs.getString("last_name");
                            boolean isAnon    = rs.getBoolean("isAnonymous");
                    %>
                        <tr>
                            <td><%= amt %></td>
                            <td><%= placed %></td>
                            <td>
                                <%
                                    if (isAnon) {
                                        // Show anonymous, no profile link
                                        out.print("Anonymous");
                                    } else {
                                %>
                                        <a class="view-link"
                                           href="userProfileAuctions.jsp?userId=<%= bidderId %>">
                                            <%= bf %> <%= bl %>
                                        </a>
                                <%
                                    }
                                %>
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

    </main>
</body>
</html>
