<%@ page import="jakarta.servlet.http.*,java.sql.*,java.math.BigDecimal,com.cs336.pkg.ApplicationDB"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"%>

<%
    // Require login
    HttpSession currentSession = request.getSession(false);
    if (currentSession == null || currentSession.getAttribute("email") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Integer sessionUserId = (Integer) currentSession.getAttribute("user_id");

    // Target user whose auctions we want to see
    String userIdParam = request.getParameter("userId");
    int targetUserId;

    if (userIdParam != null && !userIdParam.isEmpty()) {
        try {
            targetUserId = Integer.parseInt(userIdParam);
        } catch (NumberFormatException e) {
            // invalid id -> just use current logged-in user
            targetUserId = (sessionUserId != null ? sessionUserId : -1);
        }
    } else {
        // default: show profile for the logged-in user
        targetUserId = (sessionUserId != null ? sessionUserId : -1);
    }

    if (targetUserId <= 0) {
        response.sendRedirect("home.jsp");
        return;
    }

    // Are we viewing our own profile?
    boolean viewingOwn = (sessionUserId != null && targetUserId == sessionUserId);

    // --- If this is a POST from the "anonymity" form and user is viewing their own profile,
    //     update the isAnonymous flag in the Users table before loading info.
    if ("POST".equalsIgnoreCase(request.getMethod()) && viewingOwn) {
        String anonParam = request.getParameter("isAnonymous"); // "0" or "1"
        boolean newAnon = "1".equals(anonParam); // 1 = anonymous, 0 = not anonymous

        ApplicationDB dbUpdate = new ApplicationDB();
        try (
            Connection c2 = dbUpdate.getConnection();
            PreparedStatement psUpdate = c2.prepareStatement(
                "UPDATE Users SET isAnonymous = ? WHERE user_id = ?"
            )
        ) {
            psUpdate.setBoolean(1, newAnon);
            psUpdate.setInt(2, sessionUserId);
            psUpdate.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
            // optional: you could set a request attribute for an error message
        }
        // After update, continue to load profile with fresh value
    }

    ApplicationDB db = new ApplicationDB();
    Connection conn = null;
    PreparedStatement psUser = null;
    PreparedStatement psSeller = null;
    PreparedStatement psBuyer = null;
    ResultSet rsUser = null;
    ResultSet rsSeller = null;
    ResultSet rsBuyer = null;

    String tgtFirstName = null;
    String tgtLastName  = null;
    String tgtEmail     = null;
    String tgtRole      = null;
    Boolean tgtIsAnon   = null;

    try {
        conn = db.getConnection();

        // 1) Load target user info (including isAnonymous)
        String userSql =
            "SELECT first_name, last_name, email, role, isAnonymous " +
            "FROM Users WHERE user_id = ?";

        psUser = conn.prepareStatement(userSql);
        psUser.setInt(1, targetUserId);
        rsUser = psUser.executeQuery();

        if (rsUser.next()) {
            tgtFirstName = rsUser.getString("first_name");
            tgtLastName  = rsUser.getString("last_name");
            tgtEmail     = rsUser.getString("email");
            tgtRole      = rsUser.getString("role");
            tgtIsAnon    = rsUser.getBoolean("isAnonymous");  // false if 0, true if 1
            if (rsUser.wasNull()) {
                tgtIsAnon = Boolean.FALSE; // default to false if null
            }
        } else {
            // user not found
%>
<!DOCTYPE html>
<html>
<head>
    <title>User Auctions</title>
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <main style="padding: 1.5rem; font-family: Arial, sans-serif;">
        <p style="color:red;">User not found.</p>
    </main>
</body>
</html>
<%
            return;
        }

        // 2) Auctions where this user is the seller
        String sellerSql =
            "SELECT a.auction_id, " +
            "       i.name AS item_name, " +
            "       c.name AS category_name, " +
            "       s.name AS subcategory_name, " +
            "       a.start_price, " +
            "       a.final_price, " +
            "       a.status, " +
            "       a.start_time, " +
            "       a.end_time, " +
            "       (SELECT MAX(b.amount) FROM Bids b WHERE b.auction_id = a.auction_id) AS highest_bid " +
            "FROM Auctions a " +
            "JOIN Items i ON a.item_id = i.item_id " +
            "JOIN Category c ON i.category_id = c.category_id " +
            "JOIN Subcategory s ON i.category_id = s.category_id " +
            "                 AND i.subcategory_id = s.subcategory_id " +
            "WHERE a.user_id = ? " +
            "ORDER BY a.start_time DESC";

        psSeller = conn.prepareStatement(sellerSql);
        psSeller.setInt(1, targetUserId);
        rsSeller = psSeller.executeQuery();

        // 3) Auctions where this user participated as a bidder
        String buyerSql =
            "SELECT a.auction_id, " +
            "       i.name AS item_name, " +
            "       c.name AS category_name, " +
            "       s.name AS subcategory_name, " +
            "       a.start_price, " +
            "       a.final_price, " +
            "       a.status, " +
            "       a.start_time, " +
            "       a.end_time, " +
            "       MAX(b.amount) AS user_max_bid, " +
            "       (SELECT MAX(b2.amount) FROM Bids b2 WHERE b2.auction_id = a.auction_id) AS highest_bid, " +
            "       a.winner_id " +
            "FROM Bids b " +
            "JOIN Auctions a ON b.auction_id = a.auction_id " +
            "JOIN Items i    ON a.item_id = i.item_id " +
            "JOIN Category c ON i.category_id = c.category_id " +
            "JOIN Subcategory s ON i.category_id = s.category_id " +
            "                 AND i.subcategory_id = s.subcategory_id " +
            "WHERE b.bidder_id = ? " +
            "GROUP BY a.auction_id, i.name, c.name, s.name, " +
            "         a.start_price, a.final_price, a.status, " +
            "         a.start_time, a.end_time, a.winner_id " +
            "ORDER BY a.end_time DESC";

        psBuyer = conn.prepareStatement(buyerSql);
        psBuyer.setInt(1, targetUserId);
        rsBuyer = psBuyer.executeQuery();

    } catch (Exception e) {
        e.printStackTrace();
%>
<html>
<head>
    <title>User Auctions</title>
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <main style="padding: 1.5rem; font-family: Arial, sans-serif;">
        <p style="color:red;">Error loading user auctions: <%= e.getMessage() %></p>
    </main>
</body>
</html>
<%
        return;
    } finally {
        // we will close in the bottom of the page after HTML, to keep rs usable in JSP
    }
%>


<html>
<head>
    <title>User Auctions</title>
    <style>
        body {
            margin: 0;
            font-family: Arial, sans-serif;
        }

        main {
            padding: 1.5rem;
        }

        h2 {
            margin-bottom: 0.25rem;
        }

        .user-meta {
            color: #555;
            margin-bottom: 0.75rem;
        }

        .own-actions {
            margin-bottom: 1.25rem;
        }

        .danger-link-btn {
            display: inline-block;
            text-decoration: none;
            background-color: #fff5f5;
            border: 1px solid #f5b5b5;
            color: #a40000;
            padding: 6px 10px;
            border-radius: 4px;
            font-size: 0.9rem;
        }
        .danger-link-btn:hover {
            background-color: #ffeaea;
        }

        .anon-form {
            margin: 0.5rem 0 1.25rem 0;
            padding: 0.75rem 1rem;
            border-radius: 4px;
            border: 1px solid #ddd;
            background-color: #fafafa;
            font-size: 0.9rem;
        }

        .anon-form label {
            display: block;
            margin-bottom: 4px;
        }

        .anon-form-options {
            margin-top: 4px;
            margin-bottom: 6px;
        }

        .anon-form-options label {
            display: inline-block;
            margin-right: 1rem;
        }

        .anon-form button {
            padding: 4px 10px;
            font-size: 0.85rem;
            border-radius: 4px;
            border: 1px solid #0073e6;
            background-color: #0073e6;
            color: #fff;
            cursor: pointer;
        }

        .anon-form button:hover {
            background-color: #005bb5;
        }

        .section-title {
            margin-top: 1.5rem;
            margin-bottom: 0.5rem;
        }

        table {
            border-collapse: collapse;
            width: 100%;
            margin-top: 0.5rem;
            margin-bottom: 1rem;
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

        .no-data {
            font-style: italic;
            color: #555;
        }

        .status-open {
            color: green;
            font-weight: bold;
        }

        .status-closed {
            color: #c0392b;
            font-weight: bold;
        }

        .status-other {
            color: #555;
        }

        .result-won {
            color: #27ae60;
            font-weight: bold;
        }

        .result-lost {
            color: #7f8c8d;
            font-weight: bold;
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
        <h2>User Auction Activity</h2>
        <div class="user-meta">
            <div>
                <strong><%= tgtFirstName %> <%= tgtLastName %></strong>
                (<%= tgtEmail %>)
            </div>
        </div>

        <%-- If this is the logged-in user's own profile, show anonymity controls + delete request link --%>
        <% if (viewingOwn) { %>
            <form
                method="post"
                action="userProfileAuctions.jsp?userId=<%= targetUserId %>"
                class="anon-form">
                <label><strong>Privacy / Anonymity in Bid History</strong></label>
                <div class="anon-form-options">
                    <label>
                        <input type="radio" name="isAnonymous" value="0"
                            <%= (tgtIsAnon == null || !tgtIsAnon) ? "checked" : "" %> />
                        Show my name in bid history
                    </label>
                    <label>
                        <input type="radio" name="isAnonymous" value="1"
                            <%= (tgtIsAnon != null && tgtIsAnon) ? "checked" : "" %> />
                        Keep me anonymous in bid history
                    </label>
                </div>
                <button type="submit">Save Privacy Setting</button>
            </form>


        <% } %>

        <!-- Auctions as Seller -->
        <h3 class="section-title">Auctions as Seller</h3>
        <%
            if (rsSeller == null || !rsSeller.isBeforeFirst()) {
        %>
            <p class="no-data">This user has not created any auctions as a seller.</p>
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
                    <th>Start Price ($)</th>
                    <th>Highest Bid ($)</th>
                    <th>Final Price ($)</th>
                    <th>Status</th>
                    <th>Start Time</th>
                    <th>End Time</th>
                    <th>View</th>
                </tr>
            </thead>
            <tbody>
            <%
                while (rsSeller.next()) {
                    int auctionId = rsSeller.getInt("auction_id");
                    String itemName   = rsSeller.getString("item_name");
                    String catName    = rsSeller.getString("category_name");
                    String subName    = rsSeller.getString("subcategory_name");
                    BigDecimal startP = rsSeller.getBigDecimal("start_price");
                    BigDecimal finalP = rsSeller.getBigDecimal("final_price");
                    BigDecimal highB  = rsSeller.getBigDecimal("highest_bid");
                    String status     = rsSeller.getString("status");
                    Timestamp startT  = rsSeller.getTimestamp("start_time");
                    Timestamp endT    = rsSeller.getTimestamp("end_time");

                    String statusClass;
                    if ("OPEN".equalsIgnoreCase(status)) {
                        statusClass = "status-open";
                    } else if ("CLOSED".equalsIgnoreCase(status)) {
                        statusClass = "status-closed";
                    } else {
                        statusClass = "status-other";
                    }
            %>
                <tr>
                    <td><%= auctionId %></td>
                    <td><%= itemName %></td>
                    <td><%= catName %></td>
                    <td><%= subName %></td>
                    <td><%= (startP != null ? startP.toPlainString() : "—") %></td>
                    <td><%= (highB  != null ? highB.toPlainString()  : "—") %></td>
                    <td><%= (finalP != null ? finalP.toPlainString() : "—") %></td>
                    <td class="<%= statusClass %>"><%= status %></td>
                    <td><%= (startT != null ? startT.toString() : "") %></td>
                    <td><%= (endT   != null ? endT.toString()   : "") %></td>
                    <td>
                        <a href="viewAuction.jsp?auctionId=<%= auctionId %>" class="view-link">
                            View
                        </a>
                    </td>
                </tr>
            <%
                } // while seller
            %>
            </tbody>
        </table>
        <%
            } // end seller section
        %>

        <!-- Auctions as Bidder -->
        <h3 class="section-title">Auctions as Bidder</h3>
        <%
            if (rsBuyer == null || !rsBuyer.isBeforeFirst()) {
        %>
            <p class="no-data">This user has not placed any bids on auctions.</p>
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
                    <th>Your Max Bid ($)</th>
                    <th>Highest Bid ($)</th>
                    <th>Status</th>
                    <th>Result</th>
                    <th>End Time</th>
                    <th>View</th>
                </tr>
            </thead>
            <tbody>
            <%
                while (rsBuyer.next()) {
                    int auctionId = rsBuyer.getInt("auction_id");
                    String itemName = rsBuyer.getString("item_name");
                    String catName  = rsBuyer.getString("category_name");
                    String subName  = rsBuyer.getString("subcategory_name");
                    BigDecimal userMaxBid = rsBuyer.getBigDecimal("user_max_bid");
                    BigDecimal highestBid = rsBuyer.getBigDecimal("highest_bid");
                    String status         = rsBuyer.getString("status");
                    Timestamp endT        = rsBuyer.getTimestamp("end_time");
                    int winnerId          = rsBuyer.getInt("winner_id");
                    boolean winnerIsNull  = rsBuyer.wasNull();

                    String statusClass;
                    if ("OPEN".equalsIgnoreCase(status)) {
                        statusClass = "status-open";
                    } else if ("CLOSED".equalsIgnoreCase(status)) {
                        statusClass = "status-closed";
                    } else {
                        statusClass = "status-other";
                    }

                    String resultText = "";
                    String resultClass = "";
                    if ("OPEN".equalsIgnoreCase(status)) {
                        // If auction still open: leading or outbid
                        if (highestBid != null && userMaxBid != null &&
                            userMaxBid.compareTo(highestBid) == 0) {
                            resultText  = "LEADING";
                            resultClass = "result-won";  // green-ish
                        } else {
                            resultText  = "OUTBID";
                            resultClass = "result-lost";
                        }
                    } else { // closed or other
                        if (winnerIsNull || highestBid == null) {
                            resultText  = "NO WINNER";
                            resultClass = "result-lost";
                        } else if (!winnerIsNull && winnerId == targetUserId) {
                            resultText  = "WON";
                            resultClass = "result-won";
                        } else {
                            resultText  = "LOST";
                            resultClass = "result-lost";
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
                    <td class="<%= statusClass %>"><%= status %></td>
                    <td class="<%= resultClass %>"><%= resultText %></td>
                    <td><%= (endT != null ? endT.toString() : "") %></td>
                    <td>
                        <a href="viewAuction.jsp?auctionId=<%= auctionId %>" class="view-link">
                            View
                        </a>
                    </td>
                </tr>
            <%
                } // while buyer
            %>
            </tbody>
        </table>
                <%
            } // end buyer section
        %>

        <%-- Only show this section if the logged-in user is viewing their own profile --%>
        <% if (viewingOwn) { %>
            <div class="own-actions">
                <a
                  class="danger-link-btn"
                  href="askQuestion.jsp?subject=<%= java.net.URLEncoder.encode("Request account deletion","UTF-8") %>&prefill=<%= java.net.URLEncoder.encode("Hi, I'd like to delete my account associated with this email. Please confirm next steps. Thank you!","UTF-8") %>">
                    Request Account Deletion or Information Changes
                </a>
            </div>
        <% } %>
    </main>
</body>
</html>


<%
    // Finally close resources
    try { if (rsUser   != null) rsUser.close(); } catch (Exception ignore) {}
    try { if (rsSeller != null) rsSeller.close(); } catch (Exception ignore) {}
    try { if (rsBuyer  != null) rsBuyer.close(); } catch (Exception ignore) {}
    try { if (psUser   != null) psUser.close(); } catch (Exception ignore) {}
    try { if (psSeller != null) psSeller.close(); } catch (Exception ignore) {}
    try { if (psBuyer  != null) psBuyer.close(); } catch (Exception ignore) {}
    try { if (conn     != null) conn.close(); } catch (Exception ignore) {}
%>
