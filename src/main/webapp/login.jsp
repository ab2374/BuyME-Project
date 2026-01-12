<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"%>

<%
    // If user already logged in, skip login page
    if (session != null && session.getAttribute("email") != null) {
        response.sendRedirect("home.jsp");
        return;
    }

    String errorMsg = (String) request.getAttribute("error");
%>

<!DOCTYPE html>
<html>
<head>
    <title>Login - BuyMe</title>
    <style>
        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background: #f4f4f4;
        }

        .wrapper {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .login-card {
            background: #ffffff;
            padding: 2rem 2.5rem;
            border-radius: 8px;
            box-shadow: 0 2px 12px rgba(0,0,0,0.08);
            width: 100%;
            max-width: 400px;
        }

        .login-title {
            margin: 0 0 0.25rem 0;
            font-size: 1.5rem;
            text-align: center;
        }

        .login-subtitle {
            margin: 0 0 1.5rem 0;
            font-size: 0.9rem;
            color: #666;
            text-align: center;
        }

        .form-group {
            margin-bottom: 1rem;
        }

        label {
            display: block;
            font-size: 0.9rem;
            margin-bottom: 0.25rem;
        }

        input[type="text"],
        input[type="password"] {
            width: 100%;
            padding: 0.5rem 0.6rem;
            border-radius: 4px;
            border: 1px solid #ccc;
            font-size: 0.95rem;
            box-sizing: border-box;
        }

        input[type="text"]:focus,
        input[type="password"]:focus {
            outline: none;
            border-color: #0073e6;
            box-shadow: 0 0 0 2px rgba(0,115,230,0.15);
        }

        .primary-btn {
            width: 100%;
            padding: 0.6rem;
            border: none;
            border-radius: 4px;
            background-color: #0073e6;
            color: #fff;
            font-size: 0.95rem;
            cursor: pointer;
            margin-top: 0.5rem;
        }

        .primary-btn:hover {
            background-color: #005bb5;
        }

        .error-msg {
            margin-top: 0.75rem;
            color: #b00020;
            font-size: 0.9rem;
            text-align: center;
        }

        .divider {
            margin: 1.25rem 0 0.75rem 0;
            border-top: 1px solid #e0e0e0;
        }

        .secondary-btn {
            width: 100%;
            display: inline-block;
            text-align: center;
            padding: 0.55rem;
            border-radius: 4px;
            border: 1px solid #ccc;
            background: #f9f9f9;
            color: #333;
            font-size: 0.9rem;
            text-decoration: none;
            margin-top: 0.75rem;
        }

        .secondary-btn:hover {
            background: #f0f0f0;
        }
    </style>
</head>
<body>

<div class="wrapper">
    <div class="login-card">
        <h2 class="login-title">Welcome to BuyMe</h2>
        <p class="login-subtitle">Sign in to continue to your account.</p>

        <form method="post" action="login">
            <div class="form-group">
                <label for="email">Email</label>
                <input id="email"
                       type="text"
                       name="email"
                       required
                       autocomplete="email">
            </div>

            <div class="form-group">
                <label for="password">Password</label>
                <input id="password"
                       type="password"
                       name="password"
                       required
                       autocomplete="current-password">
            </div>

            <button type="submit" class="primary-btn">Login</button>
        </form>

        <% if (errorMsg != null && !errorMsg.isEmpty()) { %>
            <div class="error-msg"><%= errorMsg %></div>
        <% } %>

        <div class="divider"></div>

        <!-- Create Account button -->
        <a href="createAccount.jsp" class="secondary-btn">
            Create a new account
        </a>
    </div>
</div>

</body>
</html>
