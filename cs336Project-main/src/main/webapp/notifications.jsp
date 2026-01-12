<%@ page import="jakarta.servlet.http.*,java.sql.*,com.cs336.pkg.ApplicationDB"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" %>

<%
    HttpSession session1 = request.getSession(false);
    if (session1 == null || session1.getAttribute("user_id") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Integer userId = (Integer) session1.getAttribute("user_id");
    ApplicationDB db = new ApplicationDB();
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = db.getConnection();

        // Mark all as read
        String sqlUpdate = "UPDATE Notifications SET is_read = 1 WHERE user_id = ? AND is_read = 0";
        ps = conn.prepareStatement(sqlUpdate);
        ps.setInt(1, userId);
        ps.executeUpdate();
        ps.close();

        // Load notifications list
        String sqlSelect = "SELECT message, created_at FROM Notifications " +
                           "WHERE user_id = ? ORDER BY created_at DESC";
        ps = conn.prepareStatement(sqlSelect);
        ps.setInt(1, userId);
        rs = ps.executeQuery();
%>

<!DOCTYPE html>
<html>
<head>
    <title>My Notifications</title>
    <style>
        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background-color: #f9f9f9;
        }

        main {
            padding: 1.5rem;
            max-width: 800px;
            margin: 0 auto;
        }

        h2 {
            margin-top: 0;
        }

        .notif-list {
            margin-top: 1rem;
        }

        .notif-item {
            background-color: #fff;
            border: 1px solid #ddd;
            border-radius: 6px;
            padding: 0.75rem 1rem;
            margin-bottom: 0.75rem;
        }

        .notif-time {
            font-size: 0.8rem;
            color: #777;
            margin-top: 0.25rem;
        }

        .back-link {
            display: inline-block;
            margin-top: 1.5rem;
            text-decoration: none;
            color: #0073e6;
        }

        .back-link:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>

    <jsp:include page="navbar.jsp" />

    <main>
        <h2>My Notifications</h2>

        <div class="notif-list">
            <%
                boolean hasAny = false;
                while (rs.next()) {
                    hasAny = true;
                    String msg = rs.getString("message");
                    Timestamp createdAt = rs.getTimestamp("created_at");
            %>
                <div class="notif-item">
                    <div><%= msg %></div>
                    <div class="notif-time">
                        <%= (createdAt != null ? createdAt.toString() : "") %>
                    </div>
                </div>
            <%
                }
                if (!hasAny) {
            %>
                <p>You have no notifications yet.</p>
            <%
                }
            %>
        </div>

        <a href="home.jsp" class="back-link">&larr; Back to Home</a>
    </main>
</body>
</html>

<%
    } catch (Exception e) {
        out.println("<p style='color:red;'>Error loading notifications: " + e.getMessage() + "</p>");
        e.printStackTrace();
    } finally {
        if (rs   != null) try { rs.close(); } catch (Exception ignore) {}
        if (ps   != null) try { ps.close(); } catch (Exception ignore) {}
        if (conn != null) try { conn.close(); } catch (Exception ignore) {}
    }
%>
