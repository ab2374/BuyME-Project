package com.cs336.pkg;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/UpdateUserServlet")
public class UpdateUserServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("email") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }

        String role = (String) session.getAttribute("role");
        if (role == null || !role.equalsIgnoreCase("CustomerRepresentative")) {
            resp.sendRedirect("home.jsp");
            return;
        }

        String userIdStr   = req.getParameter("user_id");
        String firstName   = req.getParameter("first_name");
        String lastName    = req.getParameter("last_name");
        String email       = req.getParameter("email");
        String newPassword = req.getParameter("new_password");
        String isActiveStr = req.getParameter("is_active");

        if (userIdStr == null) {
            resp.sendRedirect("manageUsers.jsp?error=1");
            return;
        }

        int userId = Integer.parseInt(userIdStr);
        boolean isActive = (isActiveStr != null && isActiveStr.equals("1"));

        ApplicationDB db = new ApplicationDB();
        Connection conn = null;

        try {
            conn = db.getConnection();

            // If no new password: update everything except password
            // If new password is given: update password too
            String sql;
            if (newPassword != null && !newPassword.trim().isEmpty()) {
                sql = "UPDATE Users " +
                      "SET first_name = ?, last_name = ?, email = ?, " +
                      "    password = ?, is_active = ? " +
                      "WHERE user_id = ?";
            } else {
                sql = "UPDATE Users " +
                      "SET first_name = ?, last_name = ?, email = ?, " +
                      "    is_active = ? " +
                      "WHERE user_id = ?";
            }

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                int idx = 1;
                ps.setString(idx++, firstName);
                ps.setString(idx++, lastName);
                ps.setString(idx++, email);

                if (newPassword != null && !newPassword.trim().isEmpty()) {
                    ps.setString(idx++, newPassword.trim());
                    ps.setBoolean(idx++, isActive);
                    ps.setInt(idx++, userId);
                } else {
                    ps.setBoolean(idx++, isActive);
                    ps.setInt(idx++, userId);
                }

                ps.executeUpdate();
            }

            resp.sendRedirect("manageUsers.jsp?updated=1");
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect("manageUsers.jsp?error=1");
        } finally {
            if (conn != null) {
                try { conn.close(); } catch (SQLException ignore) {}
            }
        }
    }
}
