<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"%>

<!DOCTYPE html>
<html>
<head>
    <title>Account Disabled - BuyMe</title>
    <style>
        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background: #f4f4f4;
        }

        /* Minimal navbar, same styling as main navbar */
        .navbar {
            background-color: #f2f2f2;
            color: #333;
            padding: 0.75rem 1.5rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid #ddd;
        }

        .nav-left {
            font-size: 1.2rem;
            font-weight: bold;
            text-decoration: none;
            color: #333;
        }

        .nav-left:hover {
            opacity: 0.8;
        }

        /* Empty right side – no buttons, no profile, etc. */
        .nav-right {
            /* kept for layout, but empty */
        }

        main {
            padding: 2rem 1.5rem;
            display: flex;
            justify-content: center;
        }

        .content-card {
            background: #ffffff;
            padding: 2rem 2.5rem;
            border-radius: 8px;
            box-shadow: 0 2px 12px rgba(0,0,0,0.08);
            max-width: 600px;
            width: 100%;
            text-align: center;
        }

        .title {
            margin-top: 0;
            margin-bottom: 0.75rem;
            font-size: 1.6rem;
        }

        .message {
            margin: 0;
            font-size: 0.98rem;
            color: #555;
        }

        .highlight {
            color: #b00020;
            font-weight: bold;
        }

        .small-note {
            margin-top: 1.25rem;
            font-size: 0.85rem;
            color: #777;
        }

        .back-link {
            display: inline-block;
            margin-top: 1.5rem;
            text-decoration: none;
            border-radius: 4px;
            border: 1px solid #ccc;
            padding: 0.5rem 0.9rem;
            font-size: 0.9rem;
            color: #333;
            background: #f9f9f9;
        }
        .back-link:hover {
            background: #f0f0f0;
        }
    </style>
</head>
<body>

<!-- Minimal navbar: just BuyMe title -->
<nav class="navbar">
    <a href="login.jsp" class="nav-left">BuyMe</a>
    <div class="nav-right"></div>
</nav>

<main>
    <div class="content-card">
        <h1 class="title">Account Disabled</h1>
        <p class="message">
            <span class="highlight">Your account has been disabled.</span><br>
            Please contact a customer representative or the system administrator
            if you believe this is an error or need further assistance.
        </p>

        <p class="small-note">
            You will not be able to access BuyMe features while your account is disabled.
        </p>

        <a href="login.jsp" class="back-link">Back to Login</a>
    </div>
</main>

</body>
</html>
