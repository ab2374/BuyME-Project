package com.cs336.pkg;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.util.*;

@WebServlet("/addCategory")
public class AddCategoryServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
        throws ServletException, IOException {

        String categoryName = trimOrNull(req.getParameter("category_name"));

        // Read all subcategory names in order (HTML uses name="subcatName")
        String[] subcatNamesRaw = req.getParameterValues("subcatName");

        if (categoryName == null || categoryName.isEmpty()) {
            req.setAttribute("categoryError", "Category name is required.");
            req.getRequestDispatcher("adminPage.jsp").forward(req, resp);
            return;
        }

        if (subcatNamesRaw == null || subcatNamesRaw.length < 3) {
            req.setAttribute("categoryError", "Please provide at least 3 subcategories.");
            req.getRequestDispatcher("adminPage.jsp").forward(req, resp);
            return;
        }

        // Clean subcategory names
        List<String> subcats = new ArrayList<>();
        for (String s : subcatNamesRaw) {
            String t = trimOrNull(s);
            if (t != null && !t.isEmpty()) subcats.add(t);
        }
        if (subcats.size() < 3) {
            req.setAttribute("categoryError", "Please provide at least 3 non-empty subcategories.");
            req.getRequestDispatcher("adminPage.jsp").forward(req, resp);
            return;
        }

        ApplicationDB db = new ApplicationDB();
        try (Connection conn = db.getConnection()) {
            conn.setAutoCommit(false);

            // 1) Insert Category
            int categoryId;
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO Category (name) VALUES (?)",
                    Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, categoryName);
                ps.executeUpdate();
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (!rs.next()) throw new SQLException("Failed to create category_id.");
                    categoryId = rs.getInt(1);
                }
            }

         // 2) Insert Subcategories (auto-increment subcategory_id, collect generated IDs in order)
            List<Integer> subcategoryIds = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO Subcategory (category_id, name) VALUES (?, ?)",
                    Statement.RETURN_GENERATED_KEYS)) {

                for (String subName : subcats) {
                    ps.setInt(1, categoryId);
                    ps.setString(2, subName);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        if (!rs.next()) throw new SQLException("Failed to generate subcategory_id.");
                        subcategoryIds.add(rs.getInt(1));
                    }
                }
            }


            // 3) Insert Fields per subcategory
            //    For each index i in the final order, read fieldName_i[]
            for (int i = 0; i < subcategoryIds.size(); i++) {
                int subId = subcategoryIds.get(i);
                String[] fields = req.getParameterValues("fieldName_" + i);
                if (fields == null) continue;

                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO Fields (category_id, subcategory_id, name) VALUES (?,?,?)")) {
                    for (String f : fields) {
                        String name = trimOrNull(f);
                        if (name == null || name.isEmpty()) continue;
                        ps.setInt(1, categoryId);
                        ps.setInt(2, subId);
                        ps.setString(3, name);
                        ps.addBatch();
                    }
                    ps.executeBatch();
                }
            }

            conn.commit();
            resp.sendRedirect("adminPage.jsp?categoryAdded=1");

        } catch (Exception e) {
            e.printStackTrace();
            req.setAttribute("categoryError", "Error creating category: " + e.getMessage());
            req.getRequestDispatcher("adminPage.jsp").forward(req, resp);
        }
    }

    private static String trimOrNull(String s) {
        if (s == null) return null;
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }
}
