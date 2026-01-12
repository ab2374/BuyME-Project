<%@ page import="jakarta.servlet.http.*,java.sql.*,com.cs336.pkg.ApplicationDB"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"%>

<%
    // Require login + rep role
    if (session == null || session.getAttribute("email") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String role = (String) session.getAttribute("role");
    Integer repId = (Integer) session.getAttribute("user_id");
    String repFirst = (String) session.getAttribute("first_name");
    String repLast  = (String) session.getAttribute("last_name");

    if (repId == null || role == null || !role.equalsIgnoreCase("CustomerRepresentative")) {
        response.sendRedirect("home.jsp");
        return;
    }

    // Optional search keyword
    String keyword = request.getParameter("q");
    if (keyword != null) {
        keyword = keyword.trim();
        if (keyword.isEmpty()) keyword = null;
    }

    ApplicationDB db = new ApplicationDB();
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
%>

<!DOCTYPE html>
<html>
<head>
    <title>Customer Representative Dashboard</title>
    
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

        .no-tickets {
            margin-top: 1rem;
            font-style: italic;
            color: #555;
        }

        .btn-small {
            display: inline-block;
            padding: 0.25rem 0.6rem;
            background: #0073e6;
            color: #fff;
            font-size: 0.8rem;
            border-radius: 4px;
            text-decoration: none;
        }

        .btn-small:hover {
            background: #005bb5;
        }

        details summary {
            cursor: pointer;
            font-size: 0.9rem;
            color: #0073e6;
            text-decoration: underline;
        }

        details p {
            margin: 0.25rem 0 0;
            white-space: pre-wrap;
            font-size: 0.88rem;
        }
    </style>
</head>
<body>

<jsp:include page="customerRepNavbar.jsp" />

<main>
    <h2>Manage Support Tickets</h2>
    

    <%-- Flash messages after answering tickets --%>
    <%
        String answered = request.getParameter("answered");
        String err      = request.getParameter("error");
        if ("1".equals(answered)) {
    %>
        <div class="message-bar message-success">
            Ticket response saved successfully.
        </div>
    <%
        } else if ("1".equals(err)) {
    %>
        <div class="message-bar message-error">
            There was an error updating that ticket. Please try again.
        </div>
    <%
        }
    %>

    <div class="top-bar">
        <div>
            <strong>All Support Tickets</strong>
        </div>

        <form method="get" action="customerRepPage.jsp" class="search-form">
            <input
                type="text"
                name="q"
                class="search-input"
                placeholder="Search by subject, question, or answer..."
                value="<%= (keyword != null ? keyword : "") %>"
            />
            <button type="submit" class="search-btn">Search</button>
            <% if (keyword != null) { %>
                <a href="customerRepPage.jsp" class="clear-link">Clear</a>
            <% } %>
        </form>
    </div>

    <% if (keyword != null) { %>
        <div class="search-info">
            Filtering tickets by keyword: <strong><%= keyword %></strong>
        </div>
    <% } %>

    <%
        try {
            conn = db.getConnection();

            StringBuilder sql = new StringBuilder(
                "SELECT t.ticket_id, t.subject, t.question_text, t.response_text, " +
                "       t.status, t.created_at, t.responded_at, " +
                "       u.user_id AS asker_id, u.first_name AS asker_first, u.last_name AS asker_last " +
                "FROM CustomerServiceTickets t " +
                "JOIN Users u ON t.user_id = u.user_id " +
                "WHERE 1=1 "
            );

            if (keyword != null) {
                sql.append("AND (t.subject LIKE ? OR t.question_text LIKE ? OR t.response_text LIKE ?) ");
            }

            // OPEN first, then ANSWERED, then CLOSED; oldest first within each group
            sql.append(
                "ORDER BY CASE " +
                "           WHEN t.status='OPEN' THEN 0 " +
                "           WHEN t.status='ANSWERED' THEN 1 " +
                "           ELSE 2 " +
                "         END, " +
                "         t.created_at ASC"
            );

            ps = conn.prepareStatement(sql.toString());
            int paramIdx = 1;
            if (keyword != null) {
                String like = "%" + keyword + "%";
                ps.setString(paramIdx++, like);
                ps.setString(paramIdx++, like);
                ps.setString(paramIdx++, like);
            }

            rs = ps.executeQuery();

            if (!rs.isBeforeFirst()) {
    %>
        <p class="no-tickets">
            <% if (keyword == null) { %>
                There are no support tickets yet.
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
                    <th>Asker</th>
                    <th>Subject</th>
                    <th>Status</th>
                    <th>Created</th>
                    <th>Responded</th>
                    <th>Question</th>
                    <th>Answer</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
    <%
                while (rs.next()) {
                    int ticketId         = rs.getInt("ticket_id");
                    int askerId          = rs.getInt("asker_id");
                    String subject       = rs.getString("subject");
                    String questionText  = rs.getString("question_text");
                    String responseText  = rs.getString("response_text");
                    String statusVal     = rs.getString("status");
                    Timestamp createdAt  = rs.getTimestamp("created_at");
                    Timestamp respondedAt= rs.getTimestamp("responded_at");
                    String askerFirst    = rs.getString("asker_first");
                    String askerLast     = rs.getString("asker_last");

                    String statusClass;
                    if ("OPEN".equalsIgnoreCase(statusVal)) {
                        statusClass = "status-open";
                    } else if ("ANSWERED".equalsIgnoreCase(statusVal)) {
                        statusClass = "status-answered";
                    } else {
                        statusClass = "status-closed";
                    }
    %>
                <tr>
                    <td><%= ticketId %></td>
                    <td>
                        <a href="userProfile.jsp?userId=<%= askerId %>">
                            <%= askerFirst %> <%= askerLast %>
                        </a>
                    </td>
                    <td><%= subject %></td>
                    <td class="<%= statusClass %>"><%= statusVal %></td>
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
                                <summary>View answer</summary>
                                <p><%= responseText %></p>
                            </details>
                        <% } %>
                    </td>
                    <td>
                        <a href="repTicketDetail.jsp?ticketId=<%= ticketId %>" class="btn-small">
                            View / Answer
                        </a>
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
            out.println("<div class='message-bar message-error'>Error loading tickets: "
                        + e.getMessage() + "</div>");
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
