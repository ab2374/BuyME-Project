<%@ page import="jakarta.servlet.http.*,java.sql.*,com.cs336.pkg.ApplicationDB"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" %>

<%
    // Require login
    HttpSession session1 = request.getSession(false);
    if (session1 == null || session1.getAttribute("user_id") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Integer userId = (Integer) session1.getAttribute("user_id");
    String firstName = (String) session1.getAttribute("first_name");
    String lastName  = (String) session1.getAttribute("last_name");

    ApplicationDB db = new ApplicationDB();
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
%>

<!DOCTYPE html>
<html>
<head>
    <title>My Alerts</title>
    <style>
        body {
            margin: 0;
            font-family: Arial, sans-serif;
        }

        main {
            padding: 1.5rem;
        }

        h2 {
            margin-bottom: 0.5rem;
        }

        .subtitle {
            color: #555;
            margin-bottom: 1rem;
        }

        .form-box, .alerts-box {
            margin-top: 1rem;
            padding: 1rem;
            border: 1px solid #ddd;
            border-radius: 6px;
            background-color: #fafafa;
        }

        .form-row {
            margin-bottom: 0.75rem;
        }

        label {
            display: inline-block;
            width: 140px;
            font-weight: bold;
        }

        input[type="text"], select {
            padding: 4px 6px;
            font-size: 0.9rem;
            min-width: 230px;
        }

        button, input[type="submit"] {
            padding: 0.3rem 0.8rem;
            border-radius: 4px;
            border: 1px solid #ccc;
            background-color: white;
            cursor: pointer;
            font-size: 0.9rem;
        }

        button:hover, input[type="submit"]:hover {
            background-color: #e6e6e6;
        }

        table {
            border-collapse: collapse;
            width: 100%;
            margin-top: 0.75rem;
        }

        th, td {
            border: 1px solid #ddd;
            padding: 8px 10px;
            text-align: left;
            font-size: 0.9rem;
        }

        th {
            background-color: #f5f5f5;
        }

        tr:nth-child(even) {
            background-color: #fafafa;
        }

        .no-alerts {
            margin-top: 0.5rem;
            font-style: italic;
        }

        .link {
            text-decoration: none;
            color: #0073e6;
        }

        .link:hover {
            text-decoration: underline;
        }

        .delete-btn {
            color: #c0392b;
        }
    </style>
</head>
<body>

    <jsp:include page="navbar.jsp" />

    <main>
        <h2>My Alerts</h2>
        <div class="subtitle">
            Alerts for <strong><%= firstName %> <%= lastName %></strong>.
        </div>

        <!-- Create new alert -->
        <div class="form-box">
            <h3>Create New Alert</h3>
            <p style="font-size: 0.9rem; color: #666;">
                Choose a category / subcategory and optional keywords.
                Keywords will be matched against item names (e.g., "Nike", "coat", "Birkenstock").
            </p>

            <form method="post" action="createAlert">
                <div class="form-row">
                    <label for="subcategorySelect">Category / Subcategory</label>
                    <select name="catSub" id="subcategorySelect" required>
                        <option value="">-- Select --</option>
                        <%
                            try {
                                conn = db.getConnection();

                                // Load all category + subcategory pairs
                                String sqlCatSub =
                                    "SELECT c.category_id, c.name AS category_name, " +
                                    "       s.subcategory_id, s.name AS sub_name " +
                                    "FROM Category c " +
                                    "JOIN Subcategory s " +
                                    "  ON c.category_id = s.category_id " +
                                    "ORDER BY c.name, s.name";

                                ps = conn.prepareStatement(sqlCatSub);
                                rs = ps.executeQuery();

                                while (rs.next()) {
                                    int catId  = rs.getInt("category_id");
                                    int subId  = rs.getInt("subcategory_id");
                                    String cNm = rs.getString("category_name");
                                    String sNm = rs.getString("sub_name");

                                    // Encode both IDs in one value, e.g. "1:3"
                                    String value = catId + ":" + subId;
                        %>
                            <option value="<%= value %>">
                                <%= cNm %> &raquo; <%= sNm %>
                            </option>
                        <%
                                }
                                rs.close();
                                ps.close();
                            } catch (Exception e) {
                                out.println("<p style='color:red;'>Error loading categories: " + e.getMessage() + "</p>");
                                e.printStackTrace();
                            }
                        %>
                    </select>
                </div>

                <div class="form-row">
                    <label for="keywords">Keywords (optional)</label>
                    <input type="text" id="keywords" name="keywords"
                           placeholder="e.g. Nike, black, size 9">
                </div>

                <!-- Later you can add dynamic field filters (size/color) here -->

                <div class="form-row">
                    <input type="submit" value="Create Alert">
                </div>
            </form>
        </div>

        <!-- Existing alerts list -->
        <div class="alerts-box">
            <h3>Existing Alerts</h3>
            <%
                PreparedStatement ps2 = null;
                ResultSet rs2 = null;
                try {
                    if (conn == null || conn.isClosed()) {
                        conn = db.getConnection();
                    }

                    String sqlAlerts =
                        "SELECT a.alert_id, a.keywords, " +
                        "       c.name AS category_name, " +
                        "       s.name AS sub_name " +
                        "FROM Alerts a " +
                        "JOIN Category c ON a.category_id = c.category_id " +
                        "JOIN Subcategory s " +
                        "  ON a.category_id = s.category_id " +
                        " AND a.subcategory_id = s.subcategory_id " +
                        "WHERE a.user_id = ? " +
                        "ORDER BY c.name, s.name, a.alert_id";

                    ps2 = conn.prepareStatement(sqlAlerts);
                    ps2.setInt(1, userId);
                    rs2 = ps2.executeQuery();

                    if (!rs2.isBeforeFirst()) {
            %>
                        <p class="no-alerts">You don't have any alerts yet.</p>
            <%
                    } else {
            %>
                        <table>
                            <thead>
                                <tr>
                                    <th>Alert ID</th>
                                    <th>Category</th>
                                    <th>Subcategory</th>
                                    <th>Keywords</th>
                                    <th>Delete</th>
                                </tr>
                            </thead>
                            <tbody>
                            <%
                                while (rs2.next()) {
                                    int alertId = rs2.getInt("alert_id");
                                    String cNm  = rs2.getString("category_name");
                                    String sNm  = rs2.getString("sub_name");
                                    String kw   = rs2.getString("keywords");
                            %>
                                <tr>
                                    <td><%= alertId %></td>
                                    <td><%= cNm %></td>
                                    <td><%= sNm %></td>
                                    <td><%= (kw != null && !kw.isEmpty() ? kw : "—") %></td>
                                    <td>
                                        <a class="link delete-btn"
                                           href="deleteAlert?alertId=<%= alertId %>">
                                            Delete
                                        </a>
                                    </td>
                                </tr>
                            <%
                                } // while
                            %>
                            </tbody>
                        </table>
            <%
                    } // else
                } catch (Exception e) {
                    out.println("<p style='color:red;'>Error loading alerts: " + e.getMessage() + "</p>");
                    e.printStackTrace();
                } finally {
                    if (rs2 != null) try { rs2.close(); } catch (Exception ignore) {}
                    if (ps2 != null) try { ps2.close(); } catch (Exception ignore) {}
                    if (conn != null) try { conn.close(); } catch (Exception ignore) {}
                }
            %>
        </div>
    </main>
</body>
</html>
