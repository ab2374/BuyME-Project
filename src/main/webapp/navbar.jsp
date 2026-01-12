<%@ page import="jakarta.servlet.*,jakarta.servlet.http.*,java.sql.*,com.cs336.pkg.ApplicationDB"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"%>

<%
    // Use existing session if present; don't create a new one just for navbar
    HttpSession navSession = request.getSession(false);

    String firstName = null;
    String lastName  = null;
    String role      = null;
    Integer userId   = null;

    if (navSession != null) {
        userId    = (Integer) navSession.getAttribute("user_id");
        firstName = (String) navSession.getAttribute("first_name");
        lastName  = (String) navSession.getAttribute("last_name");
        role      = (String) navSession.getAttribute("role");

        Boolean isActive = null;

        if (userId != null) {
            // Re-check is_active from DB on every navbar render
            ApplicationDB db = new ApplicationDB();
            try (Connection conn = db.getConnection();
                 PreparedStatement ps = conn.prepareStatement(
                     "SELECT is_active FROM Users WHERE user_id = ?"
                 )) {

                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        isActive = rs.getBoolean("is_active");
                    } else {
                        // No row → treat as inactive
                        isActive = Boolean.FALSE;
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
                // On DB error, treat as active so we don't randomly kick users out
                isActive = Boolean.TRUE;
            }
        }

        if (isActive != null && !isActive) {
            // Account is now disabled → clear session and send them to disabled page
            navSession.invalidate();
%>
            <script>
                window.location.href = 'accountDisabled.jsp';
            </script>
<%
            return; // stop rendering navbar markup
        }
    }
%>

<nav class="navbar">
    <a href="home.jsp" class="nav-left">BuyMe</a>

    <div class="nav-right">
        <%-- Role-based dashboard buttons --%>
        <% if (role != null && role.equalsIgnoreCase("Admin")) { %>
            <a href="adminPage.jsp" class="nav-button">Admin Dashboard</a>
        <% } %>

        <% if (role != null && role.equalsIgnoreCase("CustomerRepresentative")) { %>
            <a href="customerRepPage.jsp" class="nav-button">Customer Representative Dashboard</a>
        <% } %>

        <a href="createAuction.jsp" class="nav-button">Create Auction</a>
        <a href="myAuctions.jsp" class="nav-button">My Auctions</a>
        <a href="myBids.jsp" class="nav-button">My Bids</a>
        <a href="alerts.jsp" class="nav-button">My Alerts</a>

        <%-- Only EndUser sees Support Tickets --%>
        <% if (role != null && role.equalsIgnoreCase("EndUser")) { %>
            <a href="myTickets.jsp" class="nav-button">Support Tickets</a>
        <% } %>

        <% if (firstName != null && lastName != null) { %>
            <!-- Notifications icon (only when logged in) -->
            <a href="notifications.jsp" class="notif-link" title="Notifications">
                &#128276; <!-- bell icon -->
                <span id="notifBadge" class="notif-badge">0</span>
            </a>

            <div class="profile-container">
                <span class="user-name"><%= firstName %> <%= lastName %></span>
                <div class="profile-icon">&#128100;</div>

                <div class="dropdown-menu" id="profileMenu">
                    <%-- My Profile (only if we have a user_id) --%>
                    <% if (userId != null) { %>
                        <a href="userProfileAuctions.jsp?userId=<%= userId %>">My Profile</a>
                    <% } %>
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

    .notif-link {
        position: relative;
        text-decoration: none;
        color: #333;
        font-size: 1.3rem;
    }

    .notif-link:hover {
        opacity: 0.8;
    }

    .notif-badge {
        display: none;
        position: absolute;
        top: -6px;
        right: -10px;
        background-color: red;
        color: white;
        border-radius: 999px;
        padding: 1px 5px;
        font-size: 0.7rem;
        line-height: 1;
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
        min-width: 160px;
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

        // Notifications badge auto-update
        const badge = document.getElementById("notifBadge");
        if (badge) {
            const baseUrl = "<%= request.getContextPath() %>";

            function refreshUnread() {
                fetch(baseUrl + "/getUnreadCount")
                    .then(resp => resp.text())
                    .then(text => {
                        const count = parseInt(text, 10);
                        if (!isNaN(count) && count > 0) {
                            badge.textContent = count;
                            badge.style.display = "inline-block";
                        } else {
                            badge.textContent = "0";
                            badge.style.display = "none";
                        }
                    })
                    .catch(err => {
                        console.error("Failed to load unread count", err);
                    });
            }

            refreshUnread();
            setInterval(refreshUnread, 5000);
        }
    });
</script>
