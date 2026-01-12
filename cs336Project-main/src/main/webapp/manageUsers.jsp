<%@ page import="jakarta.servlet.http.*,java.sql.*,com.cs336.pkg.ApplicationDB"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"%>

<%
    // Require login + rep
    if (session == null || session.getAttribute("email") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String role = (String) session.getAttribute("role");
    if (role == null || !role.equalsIgnoreCase("CustomerRepresentative")) {
        response.sendRedirect("home.jsp");
        return;
    }

    String keyword = request.getParameter("q");
    if (keyword != null) {
        keyword = keyword.trim();
        if (keyword.isEmpty()) keyword = null;
    }

    ApplicationDB db = new ApplicationDB();
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
%>

<!DOCTYPE html>
<html>
<head>
    <title>Manage Users</title>
    <style>
        body { margin:0; font-family:Arial,sans-serif; background:#f7f7f7; }
        main { padding:1.5rem; }
        h2 { margin-bottom:0.25rem; }

        .top-bar {
            display:flex; flex-wrap:wrap; gap:0.75rem;
            align-items:center; justify-content:space-between;
            margin-bottom:0.75rem;
        }

        .search-form { display:flex; flex-wrap:wrap; gap:0.4rem; align-items:center; }
        .search-input {
            padding:0.3rem 0.5rem; font-size:0.9rem;
            border-radius:4px; border:1px solid #ccc;
            min-width:220px;
        }
        .search-btn {
            padding:0.3rem 0.8rem; font-size:0.85rem;
            border-radius:4px; border:1px solid #0073e6;
            background:#0073e6; color:#fff; cursor:pointer;
        }
        .search-btn:hover { background:#005bb5; }
        .clear-link { font-size:0.85rem; text-decoration:none; color:#555; }
        .clear-link:hover { text-decoration:underline; }

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

        .status-active { color:#27ae60; font-weight:bold; }
        .status-inactive { color:#c0392b; font-weight:bold; }

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

        .no-users { margin-top:1rem; font-style:italic; color:#555; }
    </style>
</head>
<body>

<jsp:include page="customerRepNavbar.jsp" />

<main>
    <h2>Manage Users</h2>

    <%
        String uUpdated = request.getParameter("updated");
        String uErr     = request.getParameter("error");
        if ("1".equals(uUpdated)) {
    %>
        <div class="msg msg-ok">User information updated successfully.</div>
    <% } else if ("1".equals(uErr)) { %>
        <div class="msg msg-err">There was a problem updating the user.</div>
    <% } %>

    <div class="top-bar">
        <div><strong>All Users</strong></div>
        <form method="get" action="manageUsers.jsp" class="search-form">
            <input type="text" name="q" class="search-input"
                   placeholder="Search by name or email..."
                   value="<%= (keyword != null ? keyword : "") %>">
            <button type="submit" class="search-btn">Search</button>
            <% if (keyword != null) { %>
                <a href="manageUsers.jsp" class="clear-link">Clear</a>
            <% } %>
        </form>
    </div>

    <%
        try {
            conn = db.getConnection();
            StringBuilder sql = new StringBuilder(
                "SELECT user_id, email, first_name, last_name, role, is_active " +
                "FROM Users WHERE 1=1 "
            );
            if (keyword != null) {
                sql.append("AND (email LIKE ? OR first_name LIKE ? OR last_name LIKE ?) ");
            }
            sql.append("ORDER BY user_id ASC");

            ps = conn.prepareStatement(sql.toString());
            int idx = 1;
            if (keyword != null) {
                String like = "%" + keyword + "%";
                ps.setString(idx++, like);
                ps.setString(idx++, like);
                ps.setString(idx++, like);
            }

            rs = ps.executeQuery();
            if (!rs.isBeforeFirst()) {
    %>
        <p class="no-users">
            <% if (keyword == null) { %>
                No users found.
            <% } else { %>
                No users match your search.
            <% } %>
        </p>
    <%
            } else {
    %>
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Name</th>
                    <th>Email</th>
                    <th>Role</th>
                    <th>Status</th>
                    <th>Profile</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
    <%
                while (rs.next()) {
                    int id       = rs.getInt("user_id");
                    String email = rs.getString("email");
                    String fn    = rs.getString("first_name");
                    String ln    = rs.getString("last_name");
                    String r     = rs.getString("role");
                    boolean active = rs.getBoolean("is_active");
    %>
                <tr>
                    <td><%= id %></td>
                    <td><%= fn %> <%= ln %></td>
                    <td><%= email %></td>
                    <td><%= r %></td>
                    <td class="<%= active ? "status-active" : "status-inactive" %>">
                        <%= active ? "Active" : "Inactive" %>
                    </td>
                    <td>
                        <a href="userProfileAuctions.jsp?userId=<%= id %>" class="btn-small">
                            View Profile
                        </a>
                    </td>
                    <td>
                        <a href="editUser.jsp?userId=<%= id %>" class="btn-small">
                            Edit
                        </a>
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
            out.println("<div class='msg msg-err'>Error loading users: "
                        + e.getMessage() + "</div>");
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
