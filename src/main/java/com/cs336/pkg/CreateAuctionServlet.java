package com.cs336.pkg;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/CreateAuctionServlet")
public class CreateAuctionServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }

        Integer userId = (Integer) session.getAttribute("user_id");

        // -------- 1. Read and validate form fields --------
        String itemName      = req.getParameter("item_name");
        String condition     = req.getParameter("condition");
        String catIdStr      = req.getParameter("category_id");
        String subIdStr      = req.getParameter("subcategory_id");
        String startPriceStr = req.getParameter("start_price");
        String incStr        = req.getParameter("bid_increment");
        String minPriceStr   = req.getParameter("minimum_price");
        String endTimeStr    = req.getParameter("end_time"); // from datetime-local

        if (itemName == null || itemName.trim().isEmpty() ||
            condition == null || condition.trim().isEmpty() ||
            catIdStr == null || catIdStr.trim().isEmpty() ||
            subIdStr == null || subIdStr.trim().isEmpty() ||
            startPriceStr == null || startPriceStr.trim().isEmpty() ||
            incStr == null || incStr.trim().isEmpty() ||
            minPriceStr == null || minPriceStr.trim().isEmpty() ||
            endTimeStr == null || endTimeStr.trim().isEmpty()) {

            // You could also forward back with an error message; simple redirect for now.
            resp.sendRedirect("createAuction.jsp");
            return;
        }

        int categoryId;
        int subcategoryId;
        BigDecimal startPrice;
        BigDecimal bidIncrement;
        BigDecimal minPrice;
        Timestamp startTime = new Timestamp(System.currentTimeMillis());
        Timestamp endTime;

        try {
            categoryId    = Integer.parseInt(catIdStr);
            subcategoryId = Integer.parseInt(subIdStr);
            startPrice    = new BigDecimal(startPriceStr);
            bidIncrement  = new BigDecimal(incStr);
            minPrice      = new BigDecimal(minPriceStr);

            // datetime-local comes in as "yyyy-MM-ddTHH:mm"
            String normalized = endTimeStr.replace("T", " ") + ":00"; // add seconds
            endTime = Timestamp.valueOf(normalized);

        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect("createAuction.jsp");
            return;
        }

        ApplicationDB db = new ApplicationDB();

        try (Connection conn = db.getConnection()) {
            conn.setAutoCommit(false); // group inserts in a transaction

            // -------- 2. Insert into Items --------
            int itemId;
            String insertItemSql =
                "INSERT INTO Items (seller_id, category_id, subcategory_id, name, `condition`) " +
                "VALUES (?, ?, ?, ?, ?)";

            try (PreparedStatement psItem = conn.prepareStatement(
                    insertItemSql, Statement.RETURN_GENERATED_KEYS)) {

                psItem.setInt(1, userId);
                psItem.setInt(2, categoryId);
                psItem.setInt(3, subcategoryId);
                psItem.setString(4, itemName.trim());
                psItem.setString(5, condition.trim());
                psItem.executeUpdate();

                try (ResultSet keys = psItem.getGeneratedKeys()) {
                    if (!keys.next()) {
                        conn.rollback();
                        resp.sendRedirect("createAuction.jsp");
                        return;
                    }
                    itemId = keys.getInt(1);
                }
            }

            // -------- 3. Insert into Auctions --------
            int auctionId;
            String insertAuctionSql =
                "INSERT INTO Auctions (" +
                "  item_id, user_id, start_price, bid_increment, " +
                "  start_time, end_time, minimum_price, status" +
                ") VALUES (?, ?, ?, ?, ?, ?, ?, 'OPEN')";

            try (PreparedStatement psAuc = conn.prepareStatement(
                    insertAuctionSql, Statement.RETURN_GENERATED_KEYS)) {

                psAuc.setInt(1, itemId);
                psAuc.setInt(2, userId);
                psAuc.setBigDecimal(3, startPrice);
                psAuc.setBigDecimal(4, bidIncrement);
                psAuc.setTimestamp(5, startTime);
                psAuc.setTimestamp(6, endTime);
                psAuc.setBigDecimal(7, minPrice);

                psAuc.executeUpdate();

                try (ResultSet keys = psAuc.getGeneratedKeys()) {
                    if (!keys.next()) {
                        conn.rollback();
                        resp.sendRedirect("createAuction.jsp");
                        return;
                    }
                    auctionId = keys.getInt(1);
                }
            }

            // -------- 4. Insert dynamic field values (ItemFieldValues) --------
            // This assumes your getFields.jsp / servlet outputs inputs named "field_<field_id>"
            String fieldsSql =
                "SELECT field_id FROM Fields " +
                "WHERE category_id = ? AND subcategory_id = ?";

            try (PreparedStatement psFields = conn.prepareStatement(fieldsSql)) {
                psFields.setInt(1, categoryId);
                psFields.setInt(2, subcategoryId);

                try (ResultSet rsFields = psFields.executeQuery()) {
                    List<Integer> fieldIds = new ArrayList<>();

                    while (rsFields.next()) {
                        fieldIds.add(rsFields.getInt("field_id"));
                    }

                    String insertFV =
                        "INSERT INTO ItemFieldValues (item_id, field_id, value) " +
                        "VALUES (?, ?, ?)";

                    try (PreparedStatement psFV = conn.prepareStatement(insertFV)) {
                        for (int fieldId : fieldIds) {
                            String paramName = "field_" + fieldId;
                            String val = req.getParameter(paramName);
                            if (val != null && !val.trim().isEmpty()) {
                                psFV.setInt(1, itemId);
                                psFV.setInt(2, fieldId);
                                psFV.setString(3, val.trim());
                                psFV.addBatch();
                            }
                        }
                        psFV.executeBatch();
                    }
                }
            }

            // -------- 5. Match alerts & insert notifications --------
            // VERY IMPORTANT: wrap this in its own try/catch so auction creation
            // cannot be broken by a bug in alert/notification logic.
            try {
                String alertSql =
                    "SELECT alert_id, user_id, keywords " +
                    "FROM Alerts " +
                    "WHERE category_id = ? AND subcategory_id = ?";

                try (PreparedStatement psAlert = conn.prepareStatement(alertSql)) {
                    psAlert.setInt(1, categoryId);
                    psAlert.setInt(2, subcategoryId);

                    try (ResultSet rsAlerts = psAlert.executeQuery()) {

                        String notifSql =
                            "INSERT INTO Notifications (user_id, message) VALUES (?, ?)";

                        while (rsAlerts.next()) {
                            int alertUserId = rsAlerts.getInt("user_id");
                            String kw       = rsAlerts.getString("keywords"); // may be null

                            boolean matches = false;

                            if (kw == null || kw.trim().isEmpty()) {
                                // No keywords → any auction in this cat/subcat matches
                                matches = true;
                            } else {
                                String lowerName = itemName.toLowerCase();
                                String[] tokens  = kw.split(",");
                                for (String t : tokens) {
                                    String token = t.trim().toLowerCase();
                                    if (!token.isEmpty() && lowerName.contains(token)) {
                                        matches = true;
                                        break;
                                    }
                                }
                            }

                            if (matches) {
                            	String baseUrl = req.getContextPath();
                            	String auctionLink = baseUrl + "/placeBid.jsp?auctionId=" + auctionId;

                            	String msg =
                            	    "New auction &quot;" + itemName + "&quot; (Auction ID " + auctionId + ") " +
                            	    "matches your alert. " +
                            	    "<a href='" + auctionLink + "'>View and place a bid</a>.";



                                try (PreparedStatement psNotif =
                                             conn.prepareStatement(notifSql)) {
                                    psNotif.setInt(1, alertUserId);
                                    psNotif.setString(2, msg);
                                    psNotif.executeUpdate();
                                }
                            }
                        }
                    }
                }
            } catch (Exception alertEx) {
                // Log but DO NOT rollback the whole auction if alerts fail
                alertEx.printStackTrace();
            }

            // -------- 6. Commit and redirect --------
            conn.commit();

            // Redirect to viewAuction or myAuctions; pick what you have:
            resp.sendRedirect("viewAuction.jsp?auctionId=" + auctionId);
            // Or: resp.sendRedirect("myAuctions.jsp");

        } catch (Exception e) {
            e.printStackTrace();
            // If anything before commit fails, just send back to create page.
            resp.sendRedirect("createAuction.jsp");
        }
    }
}
