<%@ page import="jakarta.servlet.http.*,java.sql.*,com.cs336.pkg.ApplicationDB"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"%>

<%
    // Require login
    if (session == null || session.getAttribute("email") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Integer userId   = (Integer) session.getAttribute("user_id");
    String firstName = (String) session.getAttribute("first_name");
    String lastName  = (String) session.getAttribute("last_name");

    if (userId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    // Read keyword search parameter
    String keyword = request.getParameter("q");
    if (keyword != null) {
        keyword = keyword.trim();
        if (keyword.isEmpty()) {
            keyword = null;
        }
    }

    ApplicationDB db = new ApplicationDB();
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
%>

<!DOCTYPE html>
<html>
<head>
    <title>My Support Tickets</title>
    <style>
        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background-color: #f7f7f7;
        }

        main {
            padding: 1.5rem;
        }

        h2 {
            margin-bottom: 0.25rem;
        }

        .subtitle {
            color: #666;
            margin-bottom: 0.75rem;
            font-size: 0.9rem;
        }

        /* Flash messages */
        .message-bar {
            margin-bottom: 0.75rem;
            padding: 0.5rem 0.75rem;
            border-radius: 4px;
            font-size: 0.9rem;
        }

        .message-success {
            background-color: #e0f5e9;
            border: 1px solid #7bcf9b;
            color: #216b3a;
        }

        .message-error {
            background-color: #fde2e0;
            border: 1px solid #f29b96;
            color: #7c2520;
        }

        .top-bar {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
            gap: 0.75rem;
            margin-top: 0.5rem;
            margin-bottom: 0.5rem;
        }

        .btn-link {
            display: inline-block;
            padding: 0.35rem 0.8rem;
            background: #0073e6;
            color: #fff;
            border-radius: 4px;
            text-decoration: none;
            font-size: 0.85rem;
        }

        .btn-link:hover {
            background: #005bb5;
        }

        /* Search form */
        .search-form {
            display: flex;
            align-items: center;
            gap: 0.4rem;
            flex-wrap: wrap;
        }

        .search-input {
            padding: 0.3rem 0.5rem;
            font-size: 0.9rem;
            border-radius: 4px;
            border: 1px solid #ccc;
            min-width: 220px;
        }

        .search-btn {
            padding: 0.3rem 0.8rem;
            font-size: 0.85rem;
            border-radius: 4px;
            border: 1px solid #0073e6;
            background: #0073e6;
            color: white;
            cursor: pointer;
        }

        .search-btn:hover {
            background: #005bb5;
        }

        .clear-link {
            font-size: 0.85rem;
            text-decoration: none;
            color: #555;
        }

        .clear-link:hover {
            text-decoration: underline;
        }

        .search-info {
            margin-top: 0.25rem;
            font-size: 0.85rem;
            color: #555;
        }

        table {
            border-collapse: collapse;
            width: 100%;
            margin-top: 1rem;
            background: #fff;
            border-radius: 6px;
            overflow: hidden;
        }

        th, td {
            border: 1px solid #eee;
            padding: 8px 10px;
            text-align: left;
            font-size: 0.9rem;
            vertical-align: top;
        }

        th {
            background-color: #f5f5f5;
        }

        tr:nth-child(even) {
            background-color: #fafafa;
        }

        .no-tickets {
            margin-top: 1rem;
            font-style: italic;
            color: #555;
        }

        .status-open {
            color: #d35400;
            font-weight: bold;
        }
        .status-answered {
            color: #27ae60;
            font-weight: bold;
        }
        .status-closed {
            color: #7f8c8d;
            font-weight: bold;
        }

        details summary {
            cursor: pointer;
            font-size: 0.9rem;
            color: #0073e6;
            text-decoration: underline;
        }

        details p {
            margin: 0.25rem 0 0;
            white-space: pre-wrap; /* keep line breaks */
            font-size: 0.88rem;
        }
    </style>
</head>
<body>

<jsp:include page="navbar.jsp" />

<main>
    <h2>My Support Tickets</h2>
    <div class="subtitle">
        Tickets submitted by <strong><%= firstName %> <%= lastName %></strong>.
    </div>

    <div class="top-bar">
        <!-- Left: Ask New Question button -->
        <a href="askQuestion.jsp" class="btn-link">Ask a New Question</a>

        <!-- Right: Keyword search -->
        <form method="get" action="myTickets.jsp" class="search-form">
            <input
                type="text"
                name="q"
                class="search-input"
                placeholder="Search tickets by keyword..."
                value="<%= (keyword != null ? keyword : "") %>"
            />
            <button type="submit" class="search-btn">Search</button>
            <% if (keyword != null) { %>
                <a href="myTickets.jsp" class="clear-link">Clear</a>
            <% } %>
        </form>
    </div>

    <% if (keyword != null) { %>
        <div class="search-info">
            Showing tickets matching keyword: <strong><%= keyword %></strong>
        </div>
    <% } %>

    <%
        // Flash messages (e.g., after submit)
        String submitted = request.getParameter("submitted");
        String errorFlag = request.getParameter("error");

        if ("1".equals(submitted)) {
    %>
        <div class="message-bar message-success">
            Your question has been submitted to customer support.
        </div>
    <%
        } else if ("1".equals(errorFlag)) {
    %>
        <div class="message-bar message-error">
            There was an error submitting your question. Please try again.
        </div>
    <%
        }

        try {
            conn = db.getConnection();

            StringBuilder sql = new StringBuilder(
                "SELECT t.ticket_id, t.subject, t.question_text, t.response_text, " +
                "       t.status, t.created_at, t.responded_at, " +
                "       u.first_name AS rep_first, u.last_name AS rep_last " +
                "FROM CustomerServiceTickets t " +
                "LEFT JOIN Users u ON t.rep_id = u.user_id " +
                "WHERE t.user_id = ? "
            );

            // If keyword present, filter by subject / question / response
            if (keyword != null) {
                sql.append("AND (t.subject LIKE ? OR t.question_text LIKE ? OR t.response_text LIKE ?) ");
            }

            sql.append("ORDER BY t.created_at DESC");

            ps = conn.prepareStatement(sql.toString());
            ps.setInt(1, userId);

            if (keyword != null) {
                String like = "%" + keyword + "%";
                ps.setString(2, like);
                ps.setString(3, like);
                ps.setString(4, like);
            }

            rs = ps.executeQuery();

            if (!rs.isBeforeFirst()) {
    %>
        <p class="no-tickets">
            <% if (keyword == null) { %>
                You have not submitted any support tickets yet.
            <% } else { %>
                No tickets matched your search.
            <% } %>
        </p>
    <%
            } else {
    %>
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Subject</th>
                    <th>Status</th>
                    <th>Created</th>
                    <th>Responded</th>
                    <th>Question</th>
                    <th>Answer</th>
                </tr>
            </thead>
            <tbody>
    <%
                while (rs.next()) {
                    int    ticketId        = rs.getInt("ticket_id");
                    String subject         = rs.getString("subject");
                    String questionText    = rs.getString("question_text");
                    String responseText    = rs.getString("response_text");
                    String status          = rs.getString("status");
                    Timestamp createdAt    = rs.getTimestamp("created_at");
                    Timestamp respondedAt  = rs.getTimestamp("responded_at");
                    String repFirst        = rs.getString("rep_first");
                    String repLast         = rs.getString("rep_last");

                    String statusClass;
                    if ("OPEN".equalsIgnoreCase(status)) {
                        statusClass = "status-open";
                    } else if ("ANSWERED".equalsIgnoreCase(status)) {
                        statusClass = "status-answered";
                    } else {
                        statusClass = "status-closed";
                    }
    %>
                <tr>
                    <td><%= ticketId %></td>
                    <td><%= subject %></td>
                    <td class="<%= statusClass %>"><%= status %></td>
                    <td><%= createdAt %></td>
                    <td><%= (respondedAt != null ? respondedAt.toString() : "—") %></td>
                    <td>
                        <details>
                            <summary>View question</summary>
                            <p><%= questionText %></p>
                        </details>
                    </td>
                    <td>
                        <% if (responseText == null || responseText.trim().isEmpty()) { %>
                            <em>Not answered yet.</em>
                        <% } else { %>
                            <details>
                                <summary>
                                    View answer
                                    <% if (repFirst != null || repLast != null) { %>
                                        (by <%= (repFirst != null ? repFirst : "") %> <%= (repLast != null ? repLast : "") %>)
                                    <% } %>
                                </summary>
                                <p><%= responseText %></p>
                            </details>
                        <% } %>
                    </td>
                </tr>
    <%
                } // end while
    %>
            </tbody>
        </table>
    <%
            } // end has tickets
        } catch (Exception e) {
            out.println("<p class='message-bar message-error'>Error loading your tickets: "
                        + e.getMessage() + "</p>");
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception ignore) {}
            if (ps != null) try { ps.close(); } catch (Exception ignore) {}
            if (conn != null) try { conn.close(); } catch (Exception ignore) {}
        }
    %>

</main>

</body>
</html>
