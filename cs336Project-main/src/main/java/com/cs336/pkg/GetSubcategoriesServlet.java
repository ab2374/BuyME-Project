package com.cs336.pkg;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

@WebServlet("/getSubcategories")
public class GetSubcategoriesServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String categoryIdParam = request.getParameter("categoryId");
        System.out.println("GetSubcategoriesServlet categoryId = " + categoryIdParam);

        response.setContentType("text/html;charset=UTF-8");

        try (PrintWriter out = response.getWriter()) {
            // Default option
            out.println("<option value=\"\">-- Select Subcategory --</option>");

            if (categoryIdParam == null || categoryIdParam.isEmpty()) {
                return;
            }

            int categoryId = Integer.parseInt(categoryIdParam);

            ApplicationDB db = new ApplicationDB();
            try (Connection conn = db.getConnection();
                 PreparedStatement ps = conn.prepareStatement(
                         "SELECT subcategory_id, name FROM Subcategory " +
                         "WHERE category_id = ? ORDER BY name")) {

                ps.setInt(1, categoryId);
                ResultSet rs = ps.executeQuery();

                while (rs.next()) {
                    int subId = rs.getInt("subcategory_id");
                    String name = rs.getString("name");
                    out.println("<option value=\"" + subId + "\">" + name + "</option>");
                }
            } catch (Exception e) {
                e.printStackTrace();
                out.println("<!-- error: " + e.getMessage() + " -->");
            }
        }
    }
}
