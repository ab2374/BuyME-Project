package com.cs336.pkg;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;

@WebServlet("/deleteAlert")
public class DeleteAlertServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }

        Integer userId = (Integer) session.getAttribute("user_id");

        String alertIdParam = req.getParameter("alertId");
        if (alertIdParam == null || alertIdParam.isEmpty()) {
            resp.sendRedirect("alerts.jsp?error=" +
                    URLEncoder.encode("Missing alertId parameter", "UTF-8"));
            return;
        }

        int alertId;
        try {
            alertId = Integer.parseInt(alertIdParam);
        } catch (NumberFormatException e) {
            resp.sendRedirect("alerts.jsp?error=" +
                    URLEncoder.encode("Invalid alertId", "UTF-8"));
            return;
        }

        ApplicationDB db = new ApplicationDB();
        try (Connection conn = db.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "DELETE FROM Alerts WHERE alert_id = ? AND user_id = ?")) {

            ps.setInt(1, alertId);
            ps.setInt(2, userId);
            int rows = ps.executeUpdate();

            if (rows == 0) {
                // either alert didn't exist or didn't belong to this user
                resp.sendRedirect("alerts.jsp?error=" +
                        URLEncoder.encode("Alert not found or not owned by you", "UTF-8"));
            } else {
                resp.sendRedirect("alerts.jsp");
            }

        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect("alerts.jsp?error=" +
                    URLEncoder.encode(e.getMessage(), "UTF-8"));
        }
    }
}
