package com.cs336.pkg;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

// Optional: if you're using your notification system
import com.cs336.pkg.NotificationUtil;

@WebServlet("/AnswerTicketServlet")
public class AnswerTicketServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("email") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }

        String role = (String) session.getAttribute("role");
        Integer repIdObj = (Integer) session.getAttribute("user_id");
        if (repIdObj == null || role == null || !role.equalsIgnoreCase("CustomerRepresentative")) {
            resp.sendRedirect("home.jsp");
            return;
        }
        int repId = repIdObj;

        String ticketIdStr   = req.getParameter("ticket_id");
        String responseText  = req.getParameter("response_text");

        if (ticketIdStr == null) {
            resp.sendRedirect("customerRepPage.jsp?error=1");
            return;
        }

        if (responseText == null || responseText.trim().isEmpty()) {
            resp.sendRedirect("repTicketDetail.jsp?ticketId=" + ticketIdStr + "&error=1");
            return;
        }

        int ticketId = Integer.parseInt(ticketIdStr);
        ApplicationDB db = new ApplicationDB();
        Connection conn = null;

        try {
            conn = db.getConnection();
            conn.setAutoCommit(false);

            // 1) Lookup the ticket's asker for notification
            int askerUserId = -1;
            String subject = null;
            String findUserSql =
                "SELECT user_id, subject FROM CustomerServiceTickets WHERE ticket_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(findUserSql)) {
                ps.setInt(1, ticketId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        askerUserId = rs.getInt("user_id");
                        subject     = rs.getString("subject");
                    } else {
                        conn.rollback();
                        resp.sendRedirect("customerRepPage.jsp?error=1");
                        return;
                    }
                }
            }

            // 2) Update ticket with response
            String updateSql =
                "UPDATE CustomerServiceTickets " +
                "SET response_text = ?, status = 'ANSWERED', rep_id = ?, responded_at = NOW() " +
                "WHERE ticket_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                ps.setString(1, responseText.trim());
                ps.setInt(2, repId);
                ps.setInt(3, ticketId);
                ps.executeUpdate();
            }

            // 3) Optional: notify the user who opened the ticket
            try {
                if (askerUserId > 0) {
                    String msg =
                        "Your support ticket #" + ticketId +
                        " (\"" + (subject != null ? subject : "Support Question") +
                        "\") has been answered.<br>" +
                        "<a href=\"myTickets.jsp\">View your support tickets</a>";
                    NotificationUtil.createNotification(askerUserId, msg);
                }
            } catch (Exception e) {
                // log only; do not rollback because of notification
                e.printStackTrace();
            }

            conn.commit();

            // Redirect back to rep dashboard with success flag
            resp.sendRedirect("customerRepPage.jsp?answered=1");

        } catch (Exception e) {
            e.printStackTrace();
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            }
            resp.sendRedirect("customerRepPage.jsp?error=1");
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); } catch (SQLException ignore) {}
            }
        }
    }
}
