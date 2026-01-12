package com.cs336.pkg;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;

@WebServlet("/getUnreadCount")
public class GetUnreadCount extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        resp.setContentType("text/plain; charset=UTF-8");
        PrintWriter out = resp.getWriter();

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            out.print("0");
            return;
        }

        int userId = (Integer) session.getAttribute("user_id");

        int unread = 0;
        ApplicationDB db = new ApplicationDB();
        try (Connection conn = db.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "SELECT COUNT(*) FROM Notifications WHERE user_id = ? AND is_read = 0"
             )) {

            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                unread = rs.getInt(1);
            }
        } catch (Exception e) {
            // You may want to log this
            unread = 0;
        }

        out.print(unread);
    }
}
