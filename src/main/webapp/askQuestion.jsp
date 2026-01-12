<%@ page import="jakarta.servlet.http.*"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" %>

<%
    // Require login
    if (session == null || session.getAttribute("user_id") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Integer userId = (Integer) session.getAttribute("user_id");
%>

<!DOCTYPE html>
<html>
<head>
    <title>Contact Customer Support</title>
    <style>
        body {
            margin: 0;
            font-family: Arial, sans-serif;
        }

        main {
            padding: 1.5rem;
        }

        h2 {
            margin-top: 0;
        }

        .card {
            max-width: 600px;
            background: #ffffff;
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 1.25rem 1.5rem;
            box-shadow: 0 2px 6px rgba(0,0,0,0.05);
        }

        .form-group {
            margin-bottom: 0.9rem;
        }

        label {
            display: block;
            font-size: 0.9rem;
            margin-bottom: 0.25rem;
        }

        input[type="text"],
        textarea {
            width: 100%;
            box-sizing: border-box;
            padding: 0.5rem 0.6rem;
            border-radius: 4px;
            border: 1px solid #ccc;
            font-size: 0.9rem;
        }

        textarea {
            resize: vertical;
            min-height: 120px;
        }

        .primary-btn {
            padding: 0.6rem 1.2rem;
            border: none;
            border-radius: 4px;
            background-color: #0073e6;
            color: #fff;
            font-size: 0.9rem;
            cursor: pointer;
        }

        .primary-btn:hover {
            background-color: #005bb5;
        }

        .message {
            margin-top: 0.75rem;
            font-size: 0.9rem;
            color: #2e7d32;
        }

        .message.error {
            color: #b00020;
        }
    </style>
</head>
<body>

    <!-- Navbar at top, full width -->
    <jsp:include page="navbar.jsp" />

    <main>
        <h2>Contact Customer Support</h2>

        <div class="card">
            <form action="SubmitTicketServlet" method="post">
                <div class="form-group">
                    <label for="subject">Subject</label>
                    <input id="subject" type="text" name="subject" required>
                </div>

                <div class="form-group">
                    <label for="question">Your Question</label>
                    <textarea id="question" name="question" required></textarea>
                </div>

                <button type="submit" class="primary-btn">Submit Question</button>
            </form>

            <%
                String submitted = request.getParameter("submitted");
                String error = request.getParameter("error");
                if ("1".equals(submitted)) {
            %>
                <div class="message">Your question has been submitted. A customer representative will respond soon.</div>
            <%
                } else if ("1".equals(error)) {
            %>
                <div class="message error">There was an error submitting your question. Please try again.</div>
            <%
                }
            %>
        </div>
    </main>

</body>
</html>
