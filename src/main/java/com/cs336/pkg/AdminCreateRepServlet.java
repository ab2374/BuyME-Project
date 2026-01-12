package com.cs336.pkg;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.*;

@WebServlet("/AdminCreateRepServlet")
public class AdminCreateRepServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Ensure only Admin can hit this
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("role") == null ||
            !"Admin".equalsIgnoreCase((String) session.getAttribute("role"))) {

            response.sendRedirect("home.jsp");
            return;
        }

        String firstName = request.getParameter("first_name");
        String lastName  = request.getParameter("last_name");
        String email     = request.getParameter("email");
        String password  = request.getParameter("password"); // plain for now

        // Basic validation
        if (firstName == null || firstName.trim().isEmpty() ||
            lastName == null  || lastName.trim().isEmpty()  ||
            email == null     || email.trim().isEmpty()     ||
            password == null  || password.trim().isEmpty()) {

            request.setAttribute("errorMessage", "All fields are required.");
            request.getRequestDispatcher("adminPage.jsp").forward(request, response);
            return;
        }

        ApplicationDB db = new ApplicationDB();
        try (Connection conn = db.getConnection()) {

            String insertSql =
                "INSERT INTO Users (password, email, first_name, last_name, isAnonymous, role, is_active) " +
                "VALUES (?, ?, ?, ?, 0, 'CustomerRepresentative', 1)";

            try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
                ps.setString(1, password);
                ps.setString(2, email);
                ps.setString(3, firstName);
                ps.setString(4, lastName);
                ps.executeUpdate();
            }

            request.setAttribute("successMessage",
                    "Customer representative account created for " + firstName + " " + lastName + " (" + email + ").");
            request.getRequestDispatcher("adminPage.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            String msg = "Error creating representative: " + e.getMessage();

            // If email is unique and we hit a duplicate
            if (e.getMessage() != null && e.getMessage().toLowerCase().contains("duplicate")) {
                msg = "A user with that email already exists.";
            }

            request.setAttribute("errorMessage", msg);
            request.getRequestDispatcher("adminPage.jsp").forward(request, response);
        }
    }
}
