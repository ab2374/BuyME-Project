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

    if (repId == null || role == null || !role.equalsIgnoreCase("CustomerRepresentative")) {
        response.sendRedirect("home.jsp");
        return;
    }

    String ticketIdParam = request.getParameter("ticketId");
    if (ticketIdParam == null) {
        out.println("<h3 style='color:red;'>No ticket specified.</h3>");
        return;
    }

    int ticketId = Integer.parseInt(ticketIdParam);

    ApplicationDB db = new ApplicationDB();
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    String subject       = null;
    String questionText  = null;
    String responseText  = null;
    String statusVal     = null;
    Timestamp createdAt  = null;
    Timestamp respondedAt= null;
    int askerId          = 0;
    String askerFirst    = null;
    String askerLast     = null;
    String askerEmail    = null;

    try {
        conn = db.getConnection();
        String sql =
            "SELECT t.ticket_id, t.subject, t.question_text, t.response_text, " +
            "       t.status, t.created_at, t.responded_at, " +
            "       u.user_id AS asker_id, u.first_name AS asker_first, " +
            "       u.last_name AS asker_last, u.email AS asker_email " +
            "FROM CustomerServiceTickets t " +
            "JOIN Users u ON t.user_id = u.user_id " +
            "WHERE t.ticket_id = ?";

        ps = conn.prepareStatement(sql);
        ps.setInt(1, ticketId);
        rs = ps.executeQuery();

        if (rs.next()) {
            subject       = rs.getString("subject");
            questionText  = rs.getString("question_text");
            responseText  = rs.getString("response_text");
            statusVal     = rs.getString("status");
            createdAt     = rs.getTimestamp("created_at");
            respondedAt   = rs.getTimestamp("responded_at");
            askerId       = rs.getInt("asker_id");
            askerFirst    = rs.getString("asker_first");
            askerLast     = rs.getString("asker_last");
            askerEmail    = rs.getString("asker_email");
        } else {
            out.println("<h3 style='color:red;'>Ticket not found.</h3>");
            if (rs != null) try { rs.close(); } catch (Exception ignore) {}
            if (ps != null) try { ps.close(); } catch (Exception ignore) {}
            if (conn != null) try { conn.close(); } catch (Exception ignore) {}
            return;
        }
    } catch (Exception e) {
        out.println("<h3 style='color:red;'>Error loading ticket: " + e.getMessage() + "</h3>");
        e.printStackTrace();
        if (rs != null) try { rs.close(); } catch (Exception ignore) {}
        if (ps != null) try { ps.close(); } catch (Exception ignore) {}
        if (conn != null) try { conn.close(); } catch (Exception ignore) {}
        return;
    } finally {
        if (rs != null) try { rs.close(); } catch (Exception ignore) {}
        if (ps != null) try { ps.close(); } catch (Exception ignore) {}
        if (conn != null) try { conn.close(); } catch (Exception ignore) {}
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Ticket #<%= ticketId %> - Support</title>
    <style>
        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background-color: #f7f7f7;
        }

        main {
            padding: 1.5rem;
        }

        .card {
            background: #fff;
            border-radius: 6px;
            border: 1px solid #ddd;
            padding: 1rem 1.25rem;
            margin-bottom: 1rem;
        }

        .card-title {
            font-weight: bold;
            margin-bottom: 0.5rem;
            font-size: 1.05rem;
        }

        .meta {
            font-size: 0.9rem;
            color: #555;
            margin-bottom: 0.4rem;
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

        pre {
            white-space: pre-wrap;
            font-family: inherit;
            font-size: 0.9rem;
        }

        .label {
            font-weight: bold;
        }

        .back-link {
            display: inline-block;
            margin-top: 0.5rem;
            text-decoration: none;
            color: #0073e6;
            font-size: 0.9rem;
        }

        .back-link:hover {
            text-decoration: underline;
        }

        .message-bar {
            margin-bottom: 0.75rem;
            padding: 0.5rem 0.75rem;
            border-radius: 4px;
            font-size: 0.9rem;
        }

        .message-error {
            background-color: #fde2e0;
            border: 1px solid #f29b96;
            color: #7c2520;
        }

        textarea {
            width: 100%;
            min-height: 120px;
            padding: 0.5rem;
            resize: vertical;
            font-family: inherit;
            font-size: 0.9rem;
        }

        .primary-btn {
            margin-top: 0.5rem;
            padding: 0.45rem 0.9rem;
            border-radius: 4px;
            border: none;
            background: #0073e6;
            color: #fff;
            font-size: 0.9rem;
            cursor: pointer;
        }

        .primary-btn:hover {
            background: #005bb5;
        }
    </style>
</head>
<body>

<jsp:include page="navbar.jsp" />

<main>
    <h2>Support Ticket #<%= ticketId %></h2>

    <a href="customerRepPage.jsp" class="back-link">&larr; Back to Dashboard</a>

    <%
        String err = request.getParameter("error");
        if ("1".equals(err)) {
    %>
        <div class="message-bar message-error">
            Please enter a non-empty response.
        </div>
    <%
        }
    %>

    <div class="card">
        <div class="card-title"><%= subject %></div>
        <div class="meta">
            Asked by:
            <a href="userProfile.jsp?userId=<%= askerId %>">
                <%= askerFirst %> <%= askerLast %>
            </a>
            (<%= askerEmail %>)<br>
            Created: <%= createdAt %><br>
            Status:
            <span class="status-<%= statusVal.toLowerCase() %>">
                <%= statusVal %>
            </span>
        </div>

        <div>
            <span class="label">Question:</span>
            <pre><%= questionText %></pre>
        </div>
    </div>

    <div class="card">
        <div class="card-title">Your Response</div>

        <% if (responseText != null && !responseText.trim().isEmpty()) { %>
            <p><strong>Current answer:</strong></p>
            <pre><%= responseText %></pre>
            <p style="font-size:0.85rem;color:#555;">
                You can update this answer by submitting a new one below.
            </p>
        <% } else { %>
            <p style="font-size:0.9rem;color:#555;">
                This ticket has not been answered yet. Enter your response below.
            </p>
        <% } %>

        <form action="AnswerTicketServlet" method="post">
            <input type="hidden" name="ticket_id" value="<%= ticketId %>">
            <textarea name="response_text" required><%= (responseText != null ? responseText : "") %></textarea>
            <br>
            <button type="submit" class="primary-btn">Save Response</button>
        </form>
    </div>
</main>

</body>
</html>
