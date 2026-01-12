package com.cs336.pkg;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/createAccount")
public class CreateAccountServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String firstName = req.getParameter("first_name");
        String lastName  = req.getParameter("last_name");
        String email     = req.getParameter("email");
        String password  = req.getParameter("password");
        String confirm   = req.getParameter("confirm_password");
        boolean anonymous = "1".equals(req.getParameter("isAnonymous"));

        // Basic validation
        if (firstName == null || firstName.trim().isEmpty() ||
            lastName  == null || lastName.trim().isEmpty()  ||
            email     == null || email.trim().isEmpty()     ||
            password  == null || password.trim().isEmpty()  ||
            confirm   == null || confirm.trim().isEmpty()) {

            req.setAttribute("error", "Please fill out all fields.");
            req.getRequestDispatcher("createAccount.jsp").forward(req, resp);
            return;
        }

        if (!password.equals(confirm)) {
            req.setAttribute("error", "Passwords do not match.");
            req.getRequestDispatcher("createAccount.jsp").forward(req, resp);
            return;
        }

        ApplicationDB db = new ApplicationDB();

        try (Connection conn = db.getConnection()) {

            // 1) Check if email already exists
            try (PreparedStatement check = conn.prepareStatement(
                    "SELECT 1 FROM Users WHERE email = ?")) {
                check.setString(1, email);
                try (ResultSet rs = check.executeQuery()) {
                    if (rs.next()) {
                        req.setAttribute("error", "An account with this email already exists.");
                        req.getRequestDispatcher("createAccount.jsp").forward(req, resp);
                        return;
                    }
                }
            }

            // 2) Insert as a normal EndUser and get generated user_id
            String insertSql =
                "INSERT INTO Users (password, email, first_name, last_name, isAnonymous, role) " +
                "VALUES (?, ?, ?, ?, ?, 'EndUser')";

            int newUserId = -1;
            try (PreparedStatement ins = conn.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {
                ins.setString(1, password);   // plain text is fine for project
                ins.setString(2, email);
                ins.setString(3, firstName.trim());
                ins.setString(4, lastName.trim());
                ins.setBoolean(5, anonymous);
                ins.executeUpdate();

                try (ResultSet keys = ins.getGeneratedKeys()) {
                    if (keys.next()) {
                        newUserId = keys.getInt(1);
                    }
                }
            }

            if (newUserId <= 0) {
                // Fallback error if we somehow didn't get an ID
                req.setAttribute("error", "Account created but could not retrieve user id.");
                req.getRequestDispatcher("createAccount.jsp").forward(req, resp);
                return;
            }

            // 3) Auto-log them in: create session and set attributes
            HttpSession session = req.getSession(true);
            session.setAttribute("email", email);
            session.setAttribute("first_name", firstName.trim());
            session.setAttribute("last_name", lastName.trim());
            session.setAttribute("role", "EndUser");
            session.setAttribute("user_id", newUserId);
            session.setAttribute("isAnonymous", anonymous);

            // 4) Redirect straight to home.jsp
            resp.sendRedirect("home.jsp");

        } catch (Exception e) {
            e.printStackTrace();
            req.setAttribute("error", "Error creating account: " + e.getMessage());
            req.getRequestDispatcher("createAccount.jsp").forward(req, resp);
        }
    }
}
