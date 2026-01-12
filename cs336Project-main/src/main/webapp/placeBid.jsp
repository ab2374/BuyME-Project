<%@ page import="java.sql.*, java.util.*, jakarta.servlet.http.*, com.cs336.pkg.ApplicationDB"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" %>

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

    String itemName        = "";
    String categoryName    = "";
    String subcategoryName = "";
    java.math.BigDecimal startPrice   = null;
    java.math.BigDecimal highestBid   = null;
    java.math.BigDecimal bidIncrement = null;
    Timestamp endTime = null;
    java.math.BigDecimal minNextBid = null;  // computed below

    // For showing existing auto-bid for this user on this auction
    java.math.BigDecimal existingAutoMax = null;
    java.math.BigDecimal existingAutoInc = null;

    // Seller info
    int sellerId = -1;
    String sellerFirstName = "";
    String sellerLastName  = "";

    // For similar auctions (same category/subcategory)
    int categoryId   = -1;
    int subcategoryId = -1;

    // Item id (for loading dynamic field values)
    int itemId = -1;

    // Lists to hold item field names/values
    List<String> fieldNames  = new ArrayList<>();
    List<String> fieldValues = new ArrayList<>();

    try {
        conn = db.getConnection();

        // Load auction info, including seller_id, status, bid_increment, highest_bid, seller name, category/subcategory ids, and item_id
        String sqlInfo =
            "SELECT a.user_id AS seller_id, a.status, " +
            "       i.item_id, " +
            "       i.name AS item_name, c.name AS category_name, s.name AS subcategory_name, " +
            "       i.category_id, i.subcategory_id, " +
            "       a.start_price, a.bid_increment, a.end_time, " +
            "       (SELECT MAX(b.amount) FROM Bids b WHERE b.auction_id = a.auction_id) AS highest_bid, " +
            "       u.first_name AS seller_first_name, u.last_name AS seller_last_name " +
            "FROM Auctions a " +
            "JOIN Items i ON a.item_id = i.item_id " +
            "JOIN Category c ON i.category_id = c.category_id " +
            "JOIN Subcategory s ON i.category_id = s.category_id AND i.subcategory_id = s.subcategory_id " +
            "JOIN Users u ON a.user_id = u.user_id " +
            "WHERE a.auction_id = ?";

        ps = conn.prepareStatement(sqlInfo);
        ps.setInt(1, auctionId);
        rs = ps.executeQuery();

        if (rs.next()) {
            sellerId         = rs.getInt("seller_id");
            String status    = rs.getString("status");
            sellerFirstName  = rs.getString("seller_first_name");
            sellerLastName   = rs.getString("seller_last_name");

            categoryId    = rs.getInt("category_id");
            subcategoryId = rs.getInt("subcategory_id");
            itemId        = rs.getInt("item_id");

            // 1) If current user is the seller, send them to the seller view instead
            if (sellerId == userId) {
                rs.close();
                ps.close();
                conn.close();
                response.sendRedirect("viewAuction.jsp?auctionId=" + auctionId);
                return;
            }

            // 2) If auction is not OPEN, send them back to home with a message flag
            if (status == null || !"OPEN".equalsIgnoreCase(status)) {
                rs.close();
                ps.close();
                conn.close();
                response.sendRedirect("home.jsp?auctionClosed=1");
                return;
            }

            // Otherwise, the auction is OPEN and user is not seller → normal bidding flow
            itemName        = rs.getString("item_name");
            categoryName    = rs.getString("category_name");
            subcategoryName = rs.getString("subcategory_name");
            startPrice      = rs.getBigDecimal("start_price");
            bidIncrement    = rs.getBigDecimal("bid_increment");
            highestBid      = rs.getBigDecimal("highest_bid");
            endTime         = rs.getTimestamp("end_time");
        } else {
            out.println("<p style='color:red;'>Auction not found.</p>");
            if (rs != null) try { rs.close(); } catch (Exception ignore) {}
            if (ps != null) try { ps.close(); } catch (Exception ignore) {}
            if (conn != null) try { conn.close(); } catch (Exception ignore) {}
            return;
        }

        // Compute minimum allowed next bid
        if (highestBid == null) {
            minNextBid = startPrice;
        } else {
            minNextBid = highestBid.add(bidIncrement);
        }

        // Close result set / statement for info query
        rs.close();
        ps.close();
        rs = null;
        ps = null;

        // ---- Load item field values for this item (Size, Color, etc.) ----
        if (itemId > 0) {
            String sqlFields =
                "SELECT f.name AS field_name, v.value " +
                "FROM ItemFieldValues v " +
                "JOIN Fields f ON v.field_id = f.field_id " +
                "WHERE v.item_id = ? " +
                "ORDER BY f.name";

            try (PreparedStatement psFields = conn.prepareStatement(sqlFields)) {
                psFields.setInt(1, itemId);
                try (ResultSet rsFields = psFields.executeQuery()) {
                    while (rsFields.next()) {
                        fieldNames.add(rsFields.getString("field_name"));
                        fieldValues.add(rsFields.getString("value"));
                    }
                }
            }
        }

        // ---- Check if current user already has an autobid on this auction ----
        try (PreparedStatement psAuto = conn.prepareStatement(
                 "SELECT max_amount, increment FROM Autobid WHERE user_id = ? AND auction_id = ?")) {
            psAuto.setInt(1, userId);
            psAuto.setInt(2, auctionId);
            try (ResultSet rsAuto = psAuto.executeQuery()) {
                if (rsAuto.next()) {
                    existingAutoMax = rsAuto.getBigDecimal("max_amount");
                    existingAutoInc = rsAuto.getBigDecimal("increment");
                }
            }
        }

    } catch (Exception e) {
        out.println("<p style='color:red;'>Error loading auction: " + e.getMessage() + "</p>");
        e.printStackTrace();
        if (rs != null) try { rs.close(); } catch (Exception ignore) {}
        if (ps != null) try { ps.close(); } catch (Exception ignore) {}
        if (conn != null) try { conn.close(); } catch (Exception ignore) {}
        return;
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Place Bid</title>

    <style>
    body {
        font-family: Arial, sans-serif;
        margin: 0;
    }
    main {
        padding: 1.5rem;
    }

    .layout {
        display: flex;
        flex-wrap: wrap;
        gap: 1.5rem;
    }

    .left-column {
        flex: 1 1 48%;
        max-width: 48%;
        min-width: 320px;
    }

    .right-column {
        flex: 1 1 48%;
        max-width: 48%;
        min-width: 320px;
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }

    .card {
        border: 1px solid #ddd;
        border-radius: 8px;
        background: #fafafa;
        padding: 1rem 1.25rem;
    }

    .card-title {
        font-weight: bold;
        margin-bottom: 0.5rem;
        font-size: 1.05rem;
    }

    .auction-meta {
        font-size: 0.9rem;
        color: #555;
        margin-bottom: 0.5rem;
    }

    .price-line {
        margin: 0.2rem 0;
    }

    label {
        display: block;
        margin-top: 8px;
        font-size: 0.9rem;
    }

    input[type="number"],
    input[type="text"] {
        width: 100%;
        padding: 6px;
        margin-top: 4px;
        box-sizing: border-box;
    }

    .primary-btn, .secondary-btn {
        margin-top: 10px;
        padding: 7px 14px;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 0.9rem;
    }

    .primary-btn {
        background-color: #0073e6;
        color: white;
    }
    .primary-btn:hover {
        background-color: #005bb5;
    }

    .secondary-btn {
        background-color: #ccc;
        color: #333;
    }
    .secondary-btn:hover {
        background-color: #b3b3b3;
    }

    .error {
        color: red;
        margin-top: 10px;
    }

    .history-card table {
        border-collapse: collapse;
        width: 100%;
        margin-top: 0.5rem;
    }
    .history-card th,
    .history-card td {
        border: 1px solid #ddd;
        padding: 6px 8px;
        text-align: left;
        font-size: 0.9rem;
    }
    .history-card th {
        background-color: #f5f5f5;
    }

    .no-bids,
    .no-similar {
        font-style: italic;
        font-size: 0.9rem;
    }

    .message-bar {
        margin-bottom: 0.75rem;
        padding: 0.5rem 0.75rem;
        border-radius: 4px;
        font-size: 0.9rem;
    }

    .message-success {
        background-color: #e0f5e9;
        border: 1px solid #7bcf9b;
        color: #216b3a;
    }

    .message-error {
        background-color: #fde2e0;
        border: 1px solid #f29b96;
        color: #7c2520;
    }

    .auto-text {
        font-size: 0.9rem;
        color: #444;
        margin-bottom: 0.75rem;
    }

    .seller-link {
        text-decoration: none;
        color: #0073e6;
    }
    .seller-link:hover {
        text-decoration: underline;
    }

    .view-link {
        text-decoration: none;
        color: #0073e6;
    }
    .view-link:hover {
        text-decoration: underline;
    }

    /* Item field list */
    .field-list {
        margin: 0.5rem 0 0 0;
        padding-left: 1.1rem;
        font-size: 0.9rem;
        color: #444;
    }

    .field-list li {
        margin: 2px 0;
    }

    @media (max-width: 900px) {
        .left-column,
        .right-column {
            max-width: 100%;
            flex: 1 1 100%;
        }
    }
</style>

</head>

<body>

<jsp:include page="navbar.jsp" />

<main>
    <h2>Place a Bid</h2>

<%
    String qError       = request.getParameter("error");
    String qAutoSet     = request.getParameter("autoBidSet");
    String qAutoStopped = request.getParameter("autoBidStopped");
    String qSuccess     = request.getParameter("success");

    if (qSuccess != null) {
%>
        <div class="message-bar message-success">
            Your bid was placed successfully.
        </div>
<%
    }
    if (qAutoSet != null) {
%>
        <div class="message-bar message-success">
            Your automatic bidding settings were saved.
        </div>
<%
    }
    if (qAutoStopped != null) {
%>
        <div class="message-bar message-success">
            Your automatic bidding for this auction has been stopped.
        </div>
<%
    }
    if (qError != null) {
%>
        <div class="message-bar message-error">
            There was a problem with your automatic bidding request (code: <%= qError %>).
        </div>
<%
    }

    String errorMsg = (String) request.getAttribute("error");
    if (errorMsg != null) {
%>
        <div class="message-bar message-error">
            <%= errorMsg %>
        </div>
<%
    }
%>

    <div class="layout">
        <!-- LEFT: auction details -->
        <div class="left-column">
            <div class="card">
                <div class="card-title"><%= itemName %></div>
                <div class="auction-meta">
                    Category: <strong><%= categoryName %></strong><br>
                    Subcategory: <strong><%= subcategoryName %></strong><br>
                    Ends at: <strong><%= endTime %></strong><br>
                    Seller:
                    <strong>
                        <a class="seller-link"
                           href="userProfileAuctions.jsp?userId=<%= sellerId %>">
                            <%= sellerFirstName %> <%= sellerLastName %>
                        </a>
                    </strong>
                </div>
                <p class="price-line">
                    Start Price: <strong>$<%= startPrice %></strong>
                </p>
                <p class="price-line">
                    Bid Increment: <strong>$<%= bidIncrement %></strong>
                </p>
                <p class="price-line">
                    Current Highest Bid:
                    <strong>
                        <%= (highestBid == null ? "No bids yet" : "$" + highestBid.toPlainString()) %>
                    </strong>
                </p>
                <p class="price-line">
                    Minimum Allowed Next Bid:
                    <strong>$<%= minNextBid.toPlainString() %></strong>
                </p>

                <% if (!fieldNames.isEmpty()) { %>
                    <div style="margin-top: 0.75rem;">
                        <strong>Item Details</strong>
                        <ul class="field-list">
                            <% for (int i = 0; i < fieldNames.size(); i++) { %>
                                <li><%= fieldNames.get(i) %>: <%= fieldValues.get(i) %></li>
                            <% } %>
                        </ul>
                    </div>
                <% } %>
            </div>
        </div>

        <!-- RIGHT: (unchanged) manual bid + autobid cards -->
        <!-- ... keep your existing RIGHT COLUMN code here unchanged ... -->


        <!-- RIGHT: manual bid card + autobid card stacked -->
        <div class="right-column">
            <!-- Manual bid card -->
            <div class="card">
                <div class="card-title">Place a Manual Bid</div>
                <form action="PlaceBidServlet" method="post">
                    <input type="hidden" name="auction_id" value="<%= auctionId %>">

                    <label>Your Bid Amount:</label>
                    <input type="number"
                           name="bid_amount"
                           step="0.01"
                           min="<%= minNextBid.toPlainString() %>"
                           required>

                    <button type="submit" class="primary-btn">Submit Bid</button>
                </form>
            </div>

            <!-- Autobid card -->
            <div class="card">
                <div class="card-title">Automatic Bidding</div>

<%
    if (existingAutoMax != null) {
%>
                <p class="auto-text">
                    You currently have an active auto-bid on this auction with:<br>
                    Max amount: <strong>$<%= existingAutoMax.toPlainString() %></strong><br>
                    Increment per raise: <strong>$<%= existingAutoInc.toPlainString() %></strong><br>
                    (Your increment must always be at least the auction bid increment
                    of $<%= bidIncrement.toPlainString() %>.)
                </p>

                <!-- Update auto-bid -->
                <form action="AutobidServlet" method="post" style="margin-bottom: 8px;">
                    <input type="hidden" name="auction_id" value="<%= auctionId %>">

                    <label>Update max auto-bid amount:</label>
                    <input type="number"
                           name="max_amount"
                           step="0.01"
                           min="<%= minNextBid.toPlainString() %>"
                           value="<%= existingAutoMax.toPlainString() %>"
                           required>

                    <label>Update auto-bid increment:</label>
                    <input type="number"
                           name="auto_increment"
                           step="0.01"
                           min="<%= bidIncrement.toPlainString() %>"
                           value="<%= existingAutoInc.toPlainString() %>"
                           required>

                    <button type="submit" class="primary-btn">Update Auto-Bid</button>
                </form>

                <!-- Stop auto-bid -->
                <form action="AutobidServlet" method="post">
                    <input type="hidden" name="auction_id" value="<%= auctionId %>">
                    <input type="hidden" name="cancel" value="1">
                    <button type="submit" class="secondary-btn">Stop Auto-Bid</button>
                </form>
<%
    } else {
%>
                <p class="auto-text">
                    You don’t have an auto-bid on this auction yet.
                    Set a maximum amount and a per-bid increment, and we’ll bid for you automatically,
                    as long as your max is not exceeded.
                </p>

                <form action="AutobidServlet" method="post">
                    <input type="hidden" name="auction_id" value="<%= auctionId %>">

                    <label>Max auto-bid amount:</label>
                    <input type="number"
                           name="max_amount"
                           step="0.01"
                           min="<%= minNextBid.toPlainString() %>"
                           required>

                    <label>Auto-bid increment:</label>
                    <input type="number"
                           name="auto_increment"
                           step="0.01"
                           min="<%= bidIncrement.toPlainString() %>"
                           required>

                    <button type="submit" class="primary-btn">Enable Auto-Bid</button>
                </form>
<%
    }
%>
            </div>
        </div>
    </div>

    <!-- BID HISTORY & SIMILAR AUCTIONS BELOW EVERYTHING -->
    <div class="card history-card" style="margin-top: 1.5rem;">
        <div class="card-title">Bid History</div>
<%
    // Load bid history AND similar auctions using same connection
    try {
        // ------------ BID HISTORY ------------
		String sqlHistory =
		    "SELECT b.amount, b.placed_time, u.first_name, u.last_name, " +
		    "       b.bidder_id, u.isAnonymous " +
		    "FROM Bids b JOIN Users u ON b.bidder_id = u.user_id " +
		    "WHERE b.auction_id = ? " +
		    "ORDER BY b.placed_time DESC, b.bid_id DESC";


        ps = conn.prepareStatement(sqlHistory);
        ps.setInt(1, auctionId);
        rs = ps.executeQuery();

        if (!rs.isBeforeFirst()) {
%>
            <p class="no-bids">No bids yet.</p>
<%
        } else {
%>
            <table>
                <tr>
                    <th>Amount</th>
                    <th>Time</th>
                    <th>Bidder</th>
                </tr>
<%
		while (rs.next()) {
		    int bidderId = rs.getInt("bidder_id");
		    java.math.BigDecimal amt = rs.getBigDecimal("amount");
		    Timestamp placed = rs.getTimestamp("placed_time");
		    String bf = rs.getString("first_name");
		    String bl = rs.getString("last_name");
		    boolean isAnon = rs.getBoolean("isAnonymous");   // or "anonymous" if that's your column
		%>
		    <tr>
		        <td>$<%= amt %></td>
		        <td><%= placed %></td>
		        <td>
		            <%
		                if (isAnon) {
		                    // Show anonymous, no link
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
            </table>
<%
        } // end bid history section

        // Close before next query
        if (rs != null) { rs.close(); rs = null; }
        if (ps != null) { ps.close(); ps = null; }

        // ------------ SIMILAR AUCTIONS (last 30 days) ------------
%>
        <hr style="margin: 1rem 0;">
        <div class="card-title">Similar Auctions (last 30 days)</div>
<%
        if (categoryId > 0 && subcategoryId > 0) {
            String sqlSimilar =
                "SELECT a.auction_id, i.name AS item_name, a.status, " +
                "       a.start_price, a.final_price, a.start_time, a.end_time, " +
                "       (SELECT MAX(b.amount) FROM Bids b WHERE b.auction_id = a.auction_id) AS highest_bid " +
                "FROM Auctions a " +
                "JOIN Items i ON a.item_id = i.item_id " +
                "WHERE i.category_id = ? " +
                "  AND i.subcategory_id = ? " +
                "  AND a.auction_id <> ? " +
                "  AND a.start_time >= DATE_SUB(NOW(), INTERVAL 1 MONTH) " +
                "  AND a.start_time <= NOW() " +
                "ORDER BY a.start_time DESC";

            ps = conn.prepareStatement(sqlSimilar);
            ps.setInt(1, categoryId);
            ps.setInt(2, subcategoryId);
            ps.setInt(3, auctionId);
            rs = ps.executeQuery();

            if (!rs.isBeforeFirst()) {
%>
            <p class="no-similar">
                No similar auctions in the last 30 days for this category and subcategory.
            </p>
<%
            } else {
%>
            <table>
                <tr>
                    <th>Auction ID</th>
                    <th>Item</th>
                    <th>Status</th>
                    <th>Start Price ($)</th>
                    <th>Highest Bid ($)</th>
                    <th>Final Price ($)</th>
                    <th>Start Time</th>
                    <th>End Time</th>
                    <th>View</th>
                    <th>Place Bid</th>
                </tr>
<%
                while (rs.next()) {
                    int simAuctionId = rs.getInt("auction_id");
                    String simItemName = rs.getString("item_name");
                    String simStatus   = rs.getString("status");
                    java.math.BigDecimal simStartPrice = rs.getBigDecimal("start_price");
                    java.math.BigDecimal simHighBid    = rs.getBigDecimal("highest_bid");
                    java.math.BigDecimal simFinalPrice = rs.getBigDecimal("final_price");
                    Timestamp simStart  = rs.getTimestamp("start_time");
                    Timestamp simEnd    = rs.getTimestamp("end_time");
%>
                <tr>
                    <td><%= simAuctionId %></td>
                    <td><%= simItemName %></td>
                    <td><%= simStatus %></td>
                    <td><%= (simStartPrice != null ? simStartPrice.toPlainString() : "—") %></td>
                    <td><%= (simHighBid    != null ? simHighBid.toPlainString()    : "—") %></td>
                    <td><%= (simFinalPrice != null ? simFinalPrice.toPlainString() : "—") %></td>
                    <td><%= (simStart != null ? simStart.toString() : "") %></td>
                    <td><%= (simEnd   != null ? simEnd.toString()   : "") %></td>
                    <td>
                        <a class="view-link"
                           href="viewAuction.jsp?auctionId=<%= simAuctionId %>">
                            View
                        </a>
                    </td>
                    <td>
                        <%
                            if ("OPEN".equalsIgnoreCase(simStatus)) {
                        %>
                            <a class="view-link"
                               href="placeBid.jsp?auctionId=<%= simAuctionId %>">
                                Place Bid
                            </a>
                        <%
                            } else {
                                out.print("—");
                            }
                        %>
                    </td>
                </tr>
<%
                } // while similar
%>
            </table>
<%
            } // else has similar
        } else {
%>
            <p class="no-similar">
                Category information is not available to show similar auctions.
            </p>
<%
        } // end categoryId/subcategoryId check

    } catch (Exception e) {
        out.println("<p style='color:red;'>Error loading bid history or similar auctions: " + e.getMessage() + "</p>");
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (Exception ignore) {}
        if (ps != null) try { ps.close(); } catch (Exception ignore) {}
        if (conn != null) try { conn.close(); } catch (Exception ignore) {}
    }
%>
    </div>
</main>

</body>
</html>
