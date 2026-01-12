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

@WebServlet("/getFields")
public class GetFieldsServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String categoryIdParam    = request.getParameter("categoryId");
        String subcategoryIdParam = request.getParameter("subcategoryId");

        response.setContentType("text/html;charset=UTF-8");

        if (categoryIdParam == null || categoryIdParam.isEmpty()
                || subcategoryIdParam == null || subcategoryIdParam.isEmpty()) {
            return;
        }

        int categoryId    = Integer.parseInt(categoryIdParam);
        int subcategoryId = Integer.parseInt(subcategoryIdParam);

        try (PrintWriter out = response.getWriter()) {
            ApplicationDB db = new ApplicationDB();
            try (Connection conn = db.getConnection();
                 PreparedStatement ps = conn.prepareStatement(
                         "SELECT field_id, name FROM Fields " +
                         "WHERE category_id = ? AND subcategory_id = ? ORDER BY name")) {

                ps.setInt(1, categoryId);
                ps.setInt(2, subcategoryId);
                ResultSet rs = ps.executeQuery();

                while (rs.next()) {
                    int fieldId    = rs.getInt("field_id");
                    String fieldName = rs.getString("name");

                    out.println("<label>" + fieldName + ":</label>");
                    out.println("<input type=\"text\" name=\"field_" + fieldId + "\" required>");
                }
            } catch (Exception e) {
                e.printStackTrace();
                out.println("<!-- error: " + e.getMessage() + " -->");
            }
        }
    }
}
