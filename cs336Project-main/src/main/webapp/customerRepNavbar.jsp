<%@ page import="jakarta.servlet.http.*"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"%>

<%
    String firstName = (String) session.getAttribute("first_name");
    String lastName  = (String) session.getAttribute("last_name");
    String role      = (String) session.getAttribute("role");
%>

<nav class="navbar">
    <!-- Left: Brand goes to rep dashboard by default -->
    <a href="customerRepPage.jsp" class="nav-left">BuyMe – Rep</a>

    <div class="nav-right">

        <!-- Rep-only tools -->
        <a href="customerRepPage.jsp" class="nav-button">Support Tickets</a>
        <a href="manageUsers.jsp" class="nav-button">Manage Users</a>
        <a href="repAuctionList.jsp" class="nav-button">Manage Auctions & Bids</a>

        <% if (firstName != null && lastName != null) { %>
            <div class="profile-container">
                <span class="user-name"><%= firstName %> <%= lastName %></span>
                <div class="profile-icon">&#128100;</div>

                <div class="dropdown-menu" id="profileMenu">
                    <a href="logout">Logout</a>
                </div>
            </div>
        <% } else { %>
            <a href="login.jsp" class="profile-link">Login</a>
        <% } %>
    </div>
</nav>

<style>
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

    .nav-right {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        font-size: 0.95rem;
    }

    .nav-button {
        text-decoration: none;
        padding: 0.3rem 0.8rem;
        border: 1px solid #ccc;
        background: white;
        border-radius: 4px;
        color: #333;
        font-size: 0.9rem;
    }

    .nav-button:hover {
        background-color: #e6e6e6;
    }

    .profile-container {
        position: relative;
        display: flex;
        align-items: center;
        cursor: pointer;
    }

    .user-name {
        margin-right: 6px;
        font-size: 0.95rem;
    }

    .profile-icon {
        font-size: 1.4rem;
        padding: 4px;
        user-select: none;
    }

    .profile-icon:hover {
        opacity: 0.75;
    }

    .dropdown-menu {
        display: none;
        position: absolute;
        right: 0;
        top: 120%;
        background: white;
        border: 1px solid #ccc;
        border-radius: 6px;
        min-width: 140px;
        padding: 6px 0;
        box-shadow: 0px 2px 8px rgba(0,0,0,0.15);
        z-index: 200;
    }

    .dropdown-menu a {
        display: block;
        padding: 8px 12px;
        text-decoration: none;
        color: #333;
        font-size: 0.9rem;
    }

    .dropdown-menu a:hover {
        background-color: #eee;
    }

    .profile-link {
        text-decoration: none;
        color: #333;
        font-size: 1.0rem;
    }
</style>

<script>
    document.addEventListener("DOMContentLoaded", () => {
        // Profile dropdown
        const icon = document.querySelector(".profile-icon");
        const menu = document.getElementById("profileMenu");

        if (icon && menu) {
            icon.addEventListener("click", (e) => {
                e.stopPropagation();
                menu.style.display = (menu.style.display === "block") ? "none" : "block";
            });

            document.addEventListener("click", () => {
                menu.style.display = "none";
            });
        }
    });
</script>
