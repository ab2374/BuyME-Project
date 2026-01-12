package com.cs336.pkg;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/SubmitTicketServlet")
public class SubmitTicketServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int userId = (Integer) session.getAttribute("user_id");
        String subject = request.getParameter("subject");
        String question = request.getParameter("question");

        ApplicationDB db = new ApplicationDB();
        try (Connection conn = db.getConnection()) {
            String sql =
                "INSERT INTO CustomerServiceTickets (user_id, subject, question_text) " +
                "VALUES (?, ?, ?)";

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ps.setString(2, subject);
                ps.setString(3, question);
                ps.executeUpdate();
            }

            response.sendRedirect("myTickets.jsp?submitted=1");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("askQuestion.jsp?error=1");
        }
    }
}
