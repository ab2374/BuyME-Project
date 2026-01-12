<%@ page import="jakarta.servlet.http.*,java.sql.*,com.cs336.pkg.ApplicationDB"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"%>

<%
    if (session == null || session.getAttribute("email") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String role = (String) session.getAttribute("role");
    if (role == null || !role.equalsIgnoreCase("CustomerRepresentative")) {
        response.sendRedirect("home.jsp");
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
    <title>Manage Auctions & Bids</title>
    <style>
        body { margin:0; font-family:Arial,sans-serif; background:#f7f7f7; }
        main { padding:1.5rem; }
        h2 { margin-bottom:0.5rem; }

        .msg {
            margin-bottom:0.75rem; padding:0.5rem 0.75rem;
            border-radius:4px; font-size:0.9rem;
        }
        .msg-ok {
            background:#e0f5e9; border:1px solid #7bcf9b; color:#216b3a;
        }
        .msg-err {
            background:#fde2e0; border:1px solid #f29b96; color:#7c2520;
        }

        table {
            border-collapse:collapse; width:100%; margin-top:0.5rem;
            background:#fff; border-radius:6px; overflow:hidden;
        }
        th, td {
            border:1px solid #eee; padding:8px 10px;
            font-size:0.9rem; text-align:left;
        }
        th { background:#f5f5f5; }
        tr:nth-child(even) { background:#fafafa; }

        .status-open { color:#27ae60; font-weight:bold; }
        .status-closed { color:#7f8c8d; font-weight:bold; }
        .status-removed { color:#c0392b; font-weight:bold; }

        .btn-small {
            display:inline-block; padding:0.25rem 0.6rem;
            font-size:0.8rem; border-radius:4px;
            text-decoration:none; border:1px solid #0073e6;
            background:#0073e6; color:#fff;
        }
        .btn-small:hover { background:#005bb5; }

        .btn-danger {
            border-color:#c0392b; background:#c0392b;
        }
        .btn-danger:hover { background:#962d22; }

        .no-auctions { margin-top:1rem; font-style:italic; color:#555; }
    </style>
</head>
<body>

<jsp:include page="customerRepNavbar.jsp" />

<main>
    <h2>Manage Auctions & Bids</h2>

    <%
        String bidDeleted   = request.getParameter("bidDeleted");
        String aucRemoved   = request.getParameter("auctionRemoved");
        String errorFlag    = request.getParameter("error");
        if ("1".equals(bidDeleted)) {
    %>
        <div class="msg msg-ok">Bid removed successfully.</div>
    <% } else if ("1".equals(aucRemoved)) { %>
        <div class="msg msg-ok">Auction marked as removed.</div>
    <% } else if ("1".equals(errorFlag)) { %>
        <div class="msg msg-err">There was an error performing the action.</div>
    <% } %>

    <%
        try {
            conn = db.getConnection();
            String sql =
                "SELECT a.auction_id, a.status, a.start_time, a.end_time, " +
                "       i.name AS item_name, " +
                "       u.user_id AS seller_id, u.first_name, u.last_name " +
                "FROM Auctions a " +
                "JOIN Items i ON a.item_id = i.item_id " +
                "JOIN Users u ON a.user_id = u.user_id " +
                "ORDER BY a.start_time DESC";

            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();

            if (!rs.isBeforeFirst()) {
    %>
        <p class="no-auctions">No auctions found.</p>
    <%
            } else {
    %>
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Item</th>
                    <th>Seller</th>
                    <th>Status</th>
                    <th>Start</th>
                    <th>End</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
    <%
                while (rs.next()) {
                    int auctionId = rs.getInt("auction_id");
                    String itemName = rs.getString("item_name");
                    String status   = rs.getString("status");
                    Timestamp st    = rs.getTimestamp("start_time");
                    Timestamp et    = rs.getTimestamp("end_time");
                    int sellerId    = rs.getInt("seller_id");
                    String sFirst   = rs.getString("first_name");
                    String sLast    = rs.getString("last_name");

                    String statusClass;
                    if ("OPEN".equalsIgnoreCase(status)) {
                        statusClass = "status-open";
                    } else if ("REMOVED_BY_REP".equalsIgnoreCase(status)) {
                        statusClass = "status-removed";
                    } else {
                        statusClass = "status-closed";
                    }
    %>
                <tr>
                    <td><%= auctionId %></td>
                    <td><%= itemName %></td>
                    <td>
                        <a href="userProfile.jsp?userId=<%= sellerId %>">
                            <%= sFirst %> <%= sLast %>
                        </a>
                    </td>
                    <td class="<%= statusClass %>"><%= status %></td>
                    <td><%= st %></td>
                    <td><%= et %></td>
                    <td>
                        <a href="repAuctionBids.jsp?auctionId=<%= auctionId %>" class="btn-small">
                            View / Remove Bids
                        </a>
                        <form action="RepRemoveAuctionServlet" method="post"
                              style="display:inline;"
                              onsubmit="return confirm('Mark this auction as removed?');">
                            <input type="hidden" name="auction_id" value="<%= auctionId %>">
                            <button type="submit" class="btn-small btn-danger">
                                Remove Auction
                            </button>
                        </form>
                    </td>
                </tr>
    <%
                } // while
    %>
            </tbody>
        </table>
    <%
            }
        } catch (Exception e) {
            out.println("<div class='msg msg-err'>Error loading auctions: " + e.getMessage() + "</div>");
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
