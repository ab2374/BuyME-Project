package com.cs336.pkg;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;

@WebServlet("/createAlert")
public class CreateAlertServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }

        int userId = (Integer) session.getAttribute("user_id");

        String catSub = req.getParameter("catSub");  // format: "categoryId:subcategoryId"
        String keywords = req.getParameter("keywords");

        if (catSub == null || catSub.trim().isEmpty()) {
            resp.sendRedirect("alerts.jsp?error=Missing+category/subcategory");
            return;
        }

        int categoryId;
        int subcategoryId;
        try {
            String[] parts = catSub.split(":");
            categoryId    = Integer.parseInt(parts[0]);
            subcategoryId = Integer.parseInt(parts[1]);
        } catch (Exception e) {
            resp.sendRedirect("alerts.jsp?error=Invalid+category+selection");
            return;
        }

        if (keywords != null) {
            keywords = keywords.trim();
            if (keywords.isEmpty()) {
                keywords = null;
            }
        }

        ApplicationDB db = new ApplicationDB();
        try (Connection conn = db.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "INSERT INTO Alerts (user_id, category_id, subcategory_id, keywords) " +
                 "VALUES (?, ?, ?, ?)"
             )) {

            ps.setInt(1, userId);
            ps.setInt(2, categoryId);
            ps.setInt(3, subcategoryId);

            if (keywords == null) {
                ps.setNull(4, java.sql.Types.VARCHAR);
            } else {
                ps.setString(4, keywords);
            }

            ps.executeUpdate();

            resp.sendRedirect("alerts.jsp");

        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect("alerts.jsp?error=" +
                              e.getMessage().replace(" ", "+"));
        }
    }
}
