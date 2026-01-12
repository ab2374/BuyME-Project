package com.cs336.pkg;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/RepDeleteBidServlet")
public class RepDeleteBidServlet extends HttpServlet {

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

        String bidIdStr    = req.getParameter("bid_id");
        String auctionIdStr= req.getParameter("auction_id");

        if (bidIdStr == null || auctionIdStr == null) {
            resp.sendRedirect("repAuctionList.jsp?error=1");
            return;
        }

        int bidId    = Integer.parseInt(bidIdStr);
        int auctionId= Integer.parseInt(auctionIdStr);

        ApplicationDB db = new ApplicationDB();
        try (Connection conn = db.getConnection()) {

            String sql = "DELETE FROM Bids WHERE bid_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, bidId);
                ps.executeUpdate();
            }

            // NOTE: per spec, we don't need to recompute past winners etc.
            resp.sendRedirect("repAuctionBids.jsp?auctionId=" + auctionId + "&deleted=1");

        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect("repAuctionBids.jsp?auctionId=" + auctionId + "&error=1");
        }
    }
}
