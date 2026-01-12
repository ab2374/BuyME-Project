<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"%>

<%
    // If user already logged in, skip create-account page
    if (session != null && session.getAttribute("email") != null) {
        response.sendRedirect("home.jsp");
        return;
    }

    String errorMsg   = (String) request.getAttribute("error");
    String successMsg = (String) request.getAttribute("success");

    // Helper to repopulate fields after error
    String paramFirst  = request.getParameter("first_name")  != null ? request.getParameter("first_name")  : "";
    String paramLast   = request.getParameter("last_name")   != null ? request.getParameter("last_name")   : "";
    String paramEmail  = request.getParameter("email")       != null ? request.getParameter("email")       : "";
%>

<!DOCTYPE html>
<html>
<head>
    <title>Create Account - BuyMe</title>
    <meta charset="UTF-8">
    <style>
        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background: #f5f5f5;
        }

        .page-container {
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }

        .card {
            background: white;
            padding: 2rem 2.5rem;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            width: 100%;
            max-width: 420px;
        }

        h2 {
            margin-top: 0;
            margin-bottom: 0.5rem;
            text-align: center;
        }

        .subtitle {
            text-align: center;
            color: #666;
            font-size: 0.9rem;
            margin-bottom: 1.5rem;
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
        input[type="email"],
        input[type="password"] {
            width: 100%;
            padding: 8px 10px;
            border-radius: 4px;
            border: 1px solid #ccc;
            box-sizing: border-box;
            font-size: 0.9rem;
        }

        .checkbox-row {
            display: flex;
            align-items: center;
            gap: 0.4rem;
            font-size: 0.85rem;
            margin-top: 0.4rem;
        }

        .btn-primary {
            width: 100%;
            padding: 9px 0;
            border: none;
            border-radius: 4px;
            background-color: #0073e6;
            color: white;
            font-size: 0.95rem;
            cursor: pointer;
            margin-top: 0.5rem;
        }

        .btn-primary:hover {
            background-color: #005bb5;
        }

        .secondary-link {
            text-align: center;
            margin-top: 0.9rem;
            font-size: 0.9rem;
        }

        .secondary-link a {
            color: #0073e6;
            text-decoration: none;
        }

        .secondary-link a:hover {
            text-decoration: underline;
        }

        .msg-error {
            margin-top: 0.6rem;
            padding: 0.5rem 0.7rem;
            background-color: #fde2e0;
            border: 1px solid #f29b96;
            color: #7c2520;
            border-radius: 4px;
            font-size: 0.85rem;
        }

        .msg-success {
            margin-top: 0.6rem;
            padding: 0.5rem 0.7rem;
            background-color: #e0f5e9;
            border: 1px solid #7bcf9b;
            color: #216b3a;
            border-radius: 4px;
            font-size: 0.85rem;
        }
    </style>
</head>
<body>

<div class="page-container">
    <div class="card">
        <h2>Create Account</h2>
        <div class="subtitle">
            Join <strong>BuyMe</strong> to start bidding and selling.
        </div>

        <!-- Messages from servlet -->
        <% if (successMsg != null) { %>
            <div class="msg-success"><%= successMsg %></div>
        <% } %>
        <% if (errorMsg != null) { %>
            <div class="msg-error"><%= errorMsg %></div>
        <% } %>

        <!-- Form posts to CreateAccountServlet (@WebServlet("/createAccount")) -->
        <form method="post" action="createAccount">
            <div class="form-group">
                <label for="first_name">First name</label>
                <input type="text" id="first_name" name="first_name"
                       value="<%= paramFirst %>" required>
            </div>

            <div class="form-group">
                <label for="last_name">Last name</label>
                <input type="text" id="last_name" name="last_name"
                       value="<%= paramLast %>" required>
            </div>

            <div class="form-group">
                <label for="email">Email address</label>
                <input type="email" id="email" name="email"
                       value="<%= paramEmail %>" required>
            </div>

            <div class="form-group">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" minlength="4" required>
            </div>

            <div class="form-group">
                <label for="confirm_password">Confirm password</label>
                <input type="password" id="confirm_password" name="confirm_password" minlength="4" required>
            </div>

            <div class="checkbox-row">
                <input type="checkbox" id="isAnonymous" name="isAnonymous" value="1">
                <label for="isAnonymous">Hide my real name from other users (anonymous bidding)</label>
            </div>

            <button type="submit" class="btn-primary">Create Account</button>
        </form>

        <div class="secondary-link">
            Already have an account?
            <a href="login.jsp">Back to Login</a>
        </div>
    </div>
</div>

</body>
</html>
