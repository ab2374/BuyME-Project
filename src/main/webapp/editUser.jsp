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

    String userIdParam = request.getParameter("userId");
    if (userIdParam == null) {
        out.println("<h3 style='color:red;'>No user specified.</h3>");
        return;
    }
    int editUserId = Integer.parseInt(userIdParam);

    ApplicationDB db = new ApplicationDB();
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    String email = null, firstName = null, lastName = null, dbRole = null;
    boolean isActive = true;

    try {
        conn = db.getConnection();
        String sql = "SELECT email, first_name, last_name, role, is_active " +
                     "FROM Users WHERE user_id = ?";
        ps = conn.prepareStatement(sql);
        ps.setInt(1, editUserId);
        rs = ps.executeQuery();

        if (rs.next()) {
            email     = rs.getString("email");
            firstName = rs.getString("first_name");
            lastName  = rs.getString("last_name");
            dbRole    = rs.getString("role");
            isActive  = rs.getBoolean("is_active");
        } else {
            out.println("<h3 style='color:red;'>User not found.</h3>");
            if (rs != null) try { rs.close(); } catch (Exception ignore) {}
            if (ps != null) try { ps.close(); } catch (Exception ignore) {}
            if (conn != null) try { conn.close(); } catch (Exception ignore) {}
            return;
        }
    } catch (Exception e) {
        out.println("<h3 style='color:red;'>Error loading user: " + e.getMessage() + "</h3>");
        e.printStackTrace();
        if (rs != null) try { rs.close(); } catch (Exception ignore) {}
        if (ps != null) try { ps.close(); } catch (Exception ignore) {}
        if (conn != null) try { conn.close(); } catch (Exception ignore) {}
        return;
    } finally {
        if (rs != null) try { rs.close(); } catch (Exception ignore) {}
        if (ps != null) try { ps.close(); } catch (Exception ignore) {}
        if (conn != null) try { conn.close(); } catch (Exception ignore) {}
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Edit User #<%= editUserId %></title>
    <style>
        body { margin:0; font-family:Arial,sans-serif; background:#f7f7f7; }
        main { padding:1.5rem; }
        .card {
            background:#fff; border:1px solid #ddd; border-radius:6px;
            padding:1rem 1.25rem; max-width:500px;
        }
        label { display:block; margin-top:0.4rem; font-size:0.9rem; }
        input[type="text"],
        input[type="email"],
        input[type="password"],
        select {
            width:100%; padding:0.35rem 0.5rem; margin-top:0.2rem;
            border-radius:4px; border:1px solid #ccc; box-sizing:border-box;
        }
        .checkbox-row { margin-top:0.4rem; font-size:0.9rem; }
        .checkbox-row input { margin-right:4px; }

        .btn {
            margin-top:0.8rem; padding:0.45rem 0.9rem;
            border-radius:4px; border:none; cursor:pointer;
            font-size:0.9rem;
        }
        .btn-primary { background:#0073e6; color:#fff; }
        .btn-primary:hover { background:#005bb5; }

        .back-link {
            display:inline-block; margin-top:0.5rem;
            text-decoration:none; color:#0073e6; font-size:0.9rem;
        }
        .back-link:hover { text-decoration:underline; }

        .help { font-size:0.8rem; color:#666; }
    </style>
</head>
<body>

<jsp:include page="customerRepNavbar.jsp" />

<main>
    <h2>Edit User #<%= editUserId %></h2>
    <a href="manageUsers.jsp" class="back-link">&larr; Back to Manage Users</a>

    <div class="card">
        <form action="UpdateUserServlet" method="post">
            <input type="hidden" name="user_id" value="<%= editUserId %>">

            <label>First Name</label>
            <input type="text" name="first_name" value="<%= firstName %>" required>

            <label>Last Name</label>
            <input type="text" name="last_name" value="<%= lastName %>" required>

            <label>Email</label>
            <input type="email" name="email" value="<%= email %>" required>

            <label>Role (view only)</label>
            <input type="text" value="<%= dbRole %>" disabled>

            <div class="checkbox-row">
                <label>
                    <input type="checkbox" name="is_active"
                           value="1" <%= (isActive ? "checked" : "") %> >
                    Account is active
                </label>
            </div>

            <label>Reset Password (optional)</label>
            <input type="password" name="new_password" placeholder="Leave blank to keep current">
            <div class="help">
                If you enter a new password here, the user's password will be reset.
            </div>

            <button type="submit" class="btn btn-primary">Save Changes</button>
        </form>
    </div>
</main>
</body>
</html>
