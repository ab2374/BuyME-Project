package com.cs336.pkg;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/RepRemoveAuctionServlet")
public class RepRemoveAuctionServlet extends HttpServlet {

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

        String auctionIdStr = req.getParameter("auction_id");
        if (auctionIdStr == null) {
            resp.sendRedirect("repAuctionList.jsp?error=1");
            return;
        }

        int auctionId = Integer.parseInt(auctionIdStr);

        ApplicationDB db = new ApplicationDB();
        try (Connection conn = db.getConnection()) {

            String sql =
                "UPDATE Auctions " +
                "SET status = 'REMOVED_BY_REP' " +
                "WHERE auction_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, auctionId);
                ps.executeUpdate();
            }

            resp.sendRedirect("repAuctionList.jsp?auctionRemoved=1");

        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect("repAuctionList.jsp?error=1");
        }
    }
}
