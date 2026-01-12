package com.cs336.pkg;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.*;
import java.sql.*;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String email = req.getParameter("email");
        String password = req.getParameter("password");

        resp.setContentType("text/html");
        PrintWriter out = resp.getWriter();

        try {
            ApplicationDB db = new ApplicationDB();
            Connection con = db.getConnection();

            if (con == null) {
                out.println("<h3>Database connection failed.</h3>");
                return;
            }

            String query = "SELECT * FROM Users WHERE email = ? AND password = ?";
            PreparedStatement ps = con.prepareStatement(query);
            ps.setString(1, email);
            ps.setString(2, password);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                // Read role and active status
                String role = rs.getString("role");
                boolean isActive = rs.getBoolean("is_active");

                // If account is disabled, send to accountDisabled.jsp
                if (!isActive) {
                    // no session, just show disabled message page
                    resp.sendRedirect("accountDisabled.jsp");
                    return;
                }

                // Create a session and store user info
                HttpSession session = req.getSession();
                session.setAttribute("email", rs.getString("email"));
                session.setAttribute("first_name", rs.getString("first_name"));
                session.setAttribute("last_name", rs.getString("last_name"));
                session.setAttribute("role", role);
                session.setAttribute("user_id", rs.getInt("user_id"));
                session.setAttribute("is_active", isActive);

                System.out.println(
                        "Login successful for user: " +
                        rs.getString("first_name") + " " + rs.getString("last_name") +
                        " (role=" + role + ")"
                );

                // Redirect based on role
                if ("Admin".equalsIgnoreCase(role)) {
                    resp.sendRedirect("adminPage.jsp");  // admin landing page
                } else if ("CustomerRepresentative".equalsIgnoreCase(role)) {
                    resp.sendRedirect("customerRepPage.jsp");  // customer rep landing page
                } else {
                    // Default: regular end user
                    resp.sendRedirect("home.jsp");
                }

            } else {
                // Invalid credentials
                out.println("<h2>❌ Invalid email or password.</h2>");
                out.println("<br><a href='login.jsp'><button>Back</button></a>");
            }

            db.closeConnection(con);

        } catch (Exception e) {
            e.printStackTrace();
            out.println("<h3>Error: " + e.getMessage() + "</h3>");
        }
    }
}
