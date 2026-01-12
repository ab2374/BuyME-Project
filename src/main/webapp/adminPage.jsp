<%@ page import="jakarta.servlet.http.*,java.sql.*,com.cs336.pkg.ApplicationDB"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" %>

<%
    // Require login
    if (session == null || session.getAttribute("email") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String role = (String) session.getAttribute("role");
    if (role == null || !role.equalsIgnoreCase("Admin")) {
        // Only admins can see this page
        response.sendRedirect("home.jsp");
        return;
    }

    String firstName = (String) session.getAttribute("first_name");
    String lastName  = (String) session.getAttribute("last_name");

    String successMsg = (String) request.getAttribute("successMessage");
    String errorMsg   = (String) request.getAttribute("errorMessage");
%>

<!DOCTYPE html>
<html>
<head>
    <title>BuyMe – Admin</title>
    <style>
        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background-color: #f9f9f9;
        }

        /* SIMPLE ADMIN NAVBAR */
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
        }

        .nav-right {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            font-size: 0.95rem;
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

        main {
            padding: 1.5rem;
        }

        h2 {
            margin-top: 0;
            margin-bottom: 0.5rem;
        }

        .subtitle {
            color: #555;
            margin-bottom: 1.5rem;
        }

        .card {
            background-color: #fff;
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 1rem 1.25rem;
            margin-bottom: 1.5rem;
        }

        .card h3 {
            margin-top: 0;
            margin-bottom: 0.75rem;
        }

        label {
            display: block;
            margin-top: 8px;
            font-size: 0.9rem;
        }

        input[type="text"],
        input[type="email"],
        input[type="password"] {
            width: 100%;
            padding: 7px;
            margin-top: 3px;
            box-sizing: border-box;
            border: 1px solid #ccc;
            border-radius: 4px;
            font-size: 0.9rem;
        }

        .primary-btn {
            margin-top: 12px;
            padding: 7px 14px;
            border-radius: 4px;
            border: none;
            background-color: #0073e6;
            color: white;
            font-size: 0.9rem;
            cursor: pointer;
        }

        .primary-btn:hover {
            background-color: #005bb5;
        }

        .message {
            padding: 0.5rem 0.75rem;
            border-radius: 4px;
            font-size: 0.9rem;
            margin-bottom: 1rem;
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

        table {
            border-collapse: collapse;
            width: 100%;
            margin-top: 0.5rem;
            font-size: 0.9rem;
        }

        th, td {
            border: 1px solid #eee;
            padding: 6px 8px;
            text-align: left;
        }

        th {
            background-color: #f5f5f5;
        }

        tr:nth-child(even) {
            background-color: #fafafa;
        }

        .badge-active {
            color: #27ae60;
            font-weight: bold;
        }
        .badge-inactive {
            color: #c0392b;
            font-weight: bold;
        }

        .stat-value {
            font-size: 1.1rem;
            font-weight: bold;
        }

        .stat-label {
            font-size: 0.9rem;
            color: #555;
        }

        .two-cols {
            display: flex;
            flex-wrap: wrap;
            gap: 1rem;
        }
        .two-cols .card-inner {
            flex: 1 1 48%;
            min-width: 280px;
        }
    </style>
</head>
<body>

    <!-- Admin-only navbar -->
    <nav class="navbar">
        <div class="nav-left">BuyMe – Admin</div>

        <div class="nav-right">
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

    <main>
        <h2>Admin Dashboard</h2>
        <div class="subtitle">
            Logged in as: <strong><%= firstName %> <%= lastName %></strong> (Admin)
        </div>

        <% if (successMsg != null) { %>
            <div class="message message-success">
                <%= successMsg %>
            </div>
        <% } %>

        <% if (errorMsg != null) { %>
            <div class="message message-error">
                <%= errorMsg %>
            </div>
        <% } %>

        <!-- CARD: Create Customer Representative -->
        <div class="card">
            <h3>Create Customer Representative Account</h3>
            <p style="font-size:0.9rem; color:#555;">
                Use this form to create new customer service representatives.
            </p>

            <form action="AdminCreateRepServlet" method="post">
                <label>First Name:</label>
                <input type="text" name="first_name" required>

                <label>Last Name:</label>
                <input type="text" name="last_name" required>

                <label>Email:</label>
                <input type="email" name="email" required>

                <label>Password:</label>
                <input type="password" name="password" required>

                <button type="submit" class="primary-btn">Create Representative</button>
            </form>
        </div>

        <!-- CARD: Existing reps -->
        <div class="card">
            <h3>Existing Customer Representatives</h3>

            <%
                ApplicationDB dbReps = new ApplicationDB();
                Connection connReps = null;
                PreparedStatement psReps = null;
                ResultSet rsReps = null;

                try {
                    connReps = dbReps.getConnection();
                    String sqlReps =
                        "SELECT user_id, first_name, last_name, email, is_active " +
                        "FROM Users WHERE role = 'CustomerRepresentative' " +
                        "ORDER BY user_id ASC";
                    psReps = connReps.prepareStatement(sqlReps);
                    rsReps = psReps.executeQuery();

                    if (!rsReps.isBeforeFirst()) {
            %>
                        <p style="font-size:0.9rem; font-style:italic;">
                            No customer representatives have been created yet.
                        </p>
            <%
                    } else {
            %>
                        <table>
                            <tr>
                                <th>ID</th>
                                <th>Name</th>
                                <th>Email</th>
                                <th>Status</th>
                            </tr>
            <%
                        while (rsReps.next()) {
                            int repId = rsReps.getInt("user_id");
                            String rFirst = rsReps.getString("first_name");
                            String rLast  = rsReps.getString("last_name");
                            String rEmail = rsReps.getString("email");
                            boolean isActive = rsReps.getBoolean("is_active");
            %>
                            <tr>
                                <td><%= repId %></td>
                                <td><%= rFirst %> <%= rLast %></td>
                                <td><%= rEmail %></td>
                                <td>
                                    <% if (isActive) { %>
                                        <span class="badge-active">Active</span>
                                    <% } else { %>
                                        <span class="badge-inactive">Inactive</span>
                                    <% } %>
                                </td>
                            </tr>
            <%
                        } // while
            %>
                        </table>
            <%
                    } // else
                } catch (Exception e) {
                    out.println("<p style='color:red;'>Error loading reps: " + e.getMessage() + "</p>");
                    e.printStackTrace();
                } finally {
                    if (rsReps != null) try { rsReps.close(); } catch (Exception ignore) {}
                    if (psReps != null) try { psReps.close(); } catch (Exception ignore) {}
                    if (connReps != null) try { connReps.close(); } catch (Exception ignore) {}
                }
            %>
        </div>

        <!-- CARD: Sales Reports -->
        <div class="card">
            <h3>Sales Reports</h3>
            <p class="stat-label">
                Based on CLOSED auctions with a winner and a non-null final price.
            </p>

            <%
                ApplicationDB dbSales = new ApplicationDB();
                Connection connSales = null;
                PreparedStatement psSales = null;
                ResultSet rsSales = null;

                java.math.BigDecimal totalEarnings = java.math.BigDecimal.ZERO;

                try {
                    connSales = dbSales.getConnection();

                    // 1) TOTAL EARNINGS
                    String sqlTotal =
                        "SELECT COALESCE(SUM(final_price), 0) AS total_earnings " +
                        "FROM Auctions " +
                        "WHERE status = 'CLOSED' AND winner_id IS NOT NULL AND final_price IS NOT NULL";

                    psSales = connSales.prepareStatement(sqlTotal);
                    rsSales = psSales.executeQuery();
                    if (rsSales.next()) {
                        java.math.BigDecimal tmp = rsSales.getBigDecimal("total_earnings");
                        if (tmp != null) totalEarnings = tmp;
                    }
                    rsSales.close();
                    psSales.close();
            %>

            <!-- TOTAL EARNINGS -->
            <div style="margin-bottom:1rem;">
                <span class="stat-label">Total Earnings (all time):</span><br>
                <span class="stat-value">
                    $<%= totalEarnings.toPlainString() %>
                </span>
            </div>

            <div class="two-cols">
                <!-- Earnings per Item (best-selling items) -->
                <div class="card-inner">
                    <h4>Earnings per Item (Top 10)</h4>
                    <%
                        String sqlPerItem =
                            "SELECT a.auction_id, i.name AS item_name, a.final_price " +
                            "FROM Auctions a " +
                            "JOIN Items i ON a.item_id = i.item_id " +
                            "WHERE a.status = 'CLOSED' " +
                            "  AND a.winner_id IS NOT NULL " +
                            "  AND a.final_price IS NOT NULL " +
                            "ORDER BY a.final_price DESC " +
                            "LIMIT 10";

                        psSales = connSales.prepareStatement(sqlPerItem);
                        rsSales = psSales.executeQuery();

                        if (!rsSales.isBeforeFirst()) {
                    %>
                            <p style="font-size:0.9rem; font-style:italic;">
                                No completed auctions yet.
                            </p>
                    <%
                        } else {
                    %>
                            <table>
                                <tr>
                                    <th>Auction ID</th>
                                    <th>Item</th>
                                    <th>Final Price ($)</th>
                                </tr>
                    <%
                            while (rsSales.next()) {
                    %>
                                <tr>
                                    <td><%= rsSales.getInt("auction_id") %></td>
                                    <td><%= rsSales.getString("item_name") %></td>
                                    <td><%= rsSales.getBigDecimal("final_price").toPlainString() %></td>
                                </tr>
                    <%
                            } // while
                    %>
                            </table>
                    <%
                        }
                        rsSales.close();
                        psSales.close();
                    %>
                </div>

                <!-- Earnings per Item Type (Category) -->
                <div class="card-inner">
                    <h4>Earnings per Item Type (Category)</h4>
                    <%
                        String sqlPerCategory =
                            "SELECT c.category_id, c.name AS category_name, " +
                            "       COALESCE(SUM(a.final_price), 0) AS total_earned " +
                            "FROM Auctions a " +
                            "JOIN Items i ON a.item_id = i.item_id " +
                            "JOIN Category c ON i.category_id = c.category_id " +
                            "WHERE a.status = 'CLOSED' " +
                            "  AND a.winner_id IS NOT NULL " +
                            "  AND a.final_price IS NOT NULL " +
                            "GROUP BY c.category_id, c.name " +
                            "ORDER BY total_earned DESC";

                        psSales = connSales.prepareStatement(sqlPerCategory);
                        rsSales = psSales.executeQuery();

                        if (!rsSales.isBeforeFirst()) {
                    %>
                            <p style="font-size:0.9rem; font-style:italic;">
                                No earnings per category yet.
                            </p>
                    <%
                        } else {
                    %>
                            <table>
                                <tr>
                                    <th>Category</th>
                                    <th>Total Earnings ($)</th>
                                </tr>
                    <%
                            while (rsSales.next()) {
                    %>
                                <tr>
                                    <td><%= rsSales.getString("category_name") %></td>
                                    <td><%= rsSales.getBigDecimal("total_earned").toPlainString() %></td>
                                </tr>
                    <%
                            } // while
                    %>
                            </table>
                    <%
                        }
                        rsSales.close();
                        psSales.close();
                    %>
                </div>
            </div> <!-- end two-cols -->

            <div class="two-cols" style="margin-top:1.25rem;">
                <!-- Earnings per Seller (End-User) + Best Sellers -->
                <div class="card-inner">
                    <h4>Earnings per Seller (End-User)</h4>
                    <p class="stat-label" style="margin-bottom:0.4rem;">
                        Sum of final_price for CLOSED auctions where they are the seller.
                    </p>
                    <%
                        String sqlPerSeller =
                            "SELECT u.user_id, u.first_name, u.last_name, u.email, " +
                            "       COALESCE(SUM(a.final_price), 0) AS total_earned, " +
                            "       COUNT(*) AS sold_count " +
                            "FROM Auctions a " +
                            "JOIN Users u ON a.user_id = u.user_id " +
                            "WHERE a.status = 'CLOSED' " +
                            "  AND a.winner_id IS NOT NULL " +
                            "  AND a.final_price IS NOT NULL " +
                            "GROUP BY u.user_id, u.first_name, u.last_name, u.email " +
                            "ORDER BY total_earned DESC";

                        psSales = connSales.prepareStatement(sqlPerSeller);
                        rsSales = psSales.executeQuery();

                        if (!rsSales.isBeforeFirst()) {
                    %>
                            <p style="font-size:0.9rem; font-style:italic;">
                                No seller earnings yet.
                            </p>
                    <%
                        } else {
                    %>
                            <table>
                                <tr>
                                    <th>User</th>
                                    <th>Email</th>
                                    <th>Auctions Sold</th>
                                    <th>Total Earned ($)</th>
                                </tr>
                    <%
                            while (rsSales.next()) {
                    %>
                                <tr>
                                    <td><%= rsSales.getString("first_name") %> <%= rsSales.getString("last_name") %></td>
                                    <td><%= rsSales.getString("email") %></td>
                                    <td><%= rsSales.getInt("sold_count") %></td>
                                    <td><%= rsSales.getBigDecimal("total_earned").toPlainString() %></td>
                                </tr>
                    <%
                            } // while
                    %>
                            </table>
                    <%
                        }
                        rsSales.close();
                        psSales.close();
                    %>

                    <h4 style="margin-top:1rem;">Best Sellers (Top 10)</h4>
                    <%
                        String sqlBestSellers =
                            "SELECT u.user_id, u.first_name, u.last_name, u.email, " +
                            "       COALESCE(SUM(a.final_price), 0) AS total_earned " +
                            "FROM Auctions a " +
                            "JOIN Users u ON a.user_id = u.user_id " +
                            "WHERE a.status = 'CLOSED' " +
                            "  AND a.winner_id IS NOT NULL " +
                            "  AND a.final_price IS NOT NULL " +
                            "GROUP BY u.user_id, u.first_name, u.last_name, u.email " +
                            "ORDER BY total_earned DESC " +
                            "LIMIT 10";

                        psSales = connSales.prepareStatement(sqlBestSellers);
                        rsSales = psSales.executeQuery();

                        if (!rsSales.isBeforeFirst()) {
                    %>
                            <p style="font-size:0.9rem; font-style:italic;">
                                No seller data yet.
                            </p>
                    <%
                        } else {
                    %>
                            <table>
                                <tr>
                                    <th>User</th>
                                    <th>Email</th>
                                    <th>Total Earned ($)</th>
                                </tr>
                    <%
                            while (rsSales.next()) {
                    %>
                                <tr>
                                    <td><%= rsSales.getString("first_name") %> <%= rsSales.getString("last_name") %></td>
                                    <td><%= rsSales.getString("email") %></td>
                                    <td><%= rsSales.getBigDecimal("total_earned").toPlainString() %></td>
                                </tr>
                    <%
                            } // while
                    %>
                            </table>
                    <%
                        }
                        rsSales.close();
                        psSales.close();
                    %>
                </div>

                <!-- Best Buyers -->
                <div class="card-inner">
                    <h4>Best Buyers (Top 10)</h4>
                    <p class="stat-label" style="margin-bottom:0.4rem;">
                        Based on total amount spent (final_price of auctions they won).
                    </p>
                    <%
                        String sqlBestBuyers =
                            "SELECT u.user_id, u.first_name, u.last_name, u.email, " +
                            "       COALESCE(SUM(a.final_price), 0) AS total_spent, " +
                            "       COUNT(*) AS won_count " +
                            "FROM Auctions a " +
                            "JOIN Users u ON a.winner_id = u.user_id " +
                            "WHERE a.status = 'CLOSED' " +
                            "  AND a.winner_id IS NOT NULL " +
                            "  AND a.final_price IS NOT NULL " +
                            "GROUP BY u.user_id, u.first_name, u.last_name, u.email " +
                            "ORDER BY total_spent DESC " +
                            "LIMIT 10";

                        psSales = connSales.prepareStatement(sqlBestBuyers);
                        rsSales = psSales.executeQuery();

                        if (!rsSales.isBeforeFirst()) {
                    %>
                            <p style="font-size:0.9rem; font-style:italic;">
                                No buyer data yet.
                            </p>
                    <%
                        } else {
                    %>
                            <table>
                                <tr>
                                    <th>User</th>
                                    <th>Email</th>
                                    <th>Auctions Won</th>
                                    <th>Total Spent ($)</th>
                                </tr>
                    <%
                            while (rsSales.next()) {
                    %>
                                <tr>
                                    <td><%= rsSales.getString("first_name") %> <%= rsSales.getString("last_name") %></td>
                                    <td><%= rsSales.getString("email") %></td>
                                    <td><%= rsSales.getInt("won_count") %></td>
                                    <td><%= rsSales.getBigDecimal("total_spent").toPlainString() %></td>
                                </tr>
                    <%
                            } // while
                    %>
                            </table>
                    <%
                        }
                        rsSales.close();
                        psSales.close();
                    %>
                </div>
            </div>

            <%
                } catch (Exception e) {
                    out.println("<p style='color:red;'>Error generating sales reports: " + e.getMessage() + "</p>");
                    e.printStackTrace();
                } finally {
                    if (rsSales != null) try { rsSales.close(); } catch (Exception ignore) {}
                    if (psSales != null) try { psSales.close(); } catch (Exception ignore) {}
                    if (connSales != null) try { connSales.close(); } catch (Exception ignore) {}
                }
            %>
        </div> <!-- end Sales Reports card -->
        
<%
    String categoryError = (String) request.getAttribute("categoryError");
    String categoryAddedFlag = request.getParameter("categoryAdded");
%>

<section class="admin-card">
    <h2 class="section-title">Add New Category &amp; Subcategories</h2>
    <p class="section-subtitle">
        Create a new category with at least three subcategories. Add fields specific to each subcategory.
    </p>

    <% if ("1".equals(categoryAddedFlag)) { %>
        <div class="msg-success">
            New category and subcategories created successfully.
        </div>
    <% } %>

    <% if (categoryError != null) { %>
        <div class="msg-error"><%= categoryError %></div>
    <% } %>

    <form method="post" action="addCategory" id="addCategoryForm">
        <!-- Category name -->
        <div class="form-row">
            <label for="category_name">Category name</label>
            <input type="text" id="category_name" name="category_name" required>
        </div>

        <!-- Subcategories (each with its own fields) -->
        <div class="form-row">
            <label>Subcategories (at least 3 required)</label>
            <div id="subcatContainer"></div>

            <button type="button" class="small-button" onclick="addSubcategory()">
                + Add another subcategory
            </button>
        </div>

        <button type="submit" class="primary-btn">Create Category</button>
    </form>
</section>

<style>
    .admin-card {
        background: #ffffff;
        border-radius: 8px;
        padding: 1.5rem 1.8rem;
        margin-top: 1.5rem;
        box-shadow: 0 1px 6px rgba(0,0,0,0.06);
        max-width: 880px;
    }
    .section-title { margin: 0 0 0.3rem 0; }
    .section-subtitle { margin: 0 0 1rem 0; font-size: 0.9rem; color: #666; }

    .form-row { margin-bottom: 1rem; }
    .form-row label { display:block; font-size:0.9rem; margin-bottom:0.25rem; font-weight:600; }
    #subcatContainer { display:flex; flex-direction:column; gap:0.75rem; }

    .subcat-card {
        border: 1px solid #ddd; border-radius:8px; padding: 0.9rem 1rem; background:#fafafa;
    }
    .subcat-header {
        display:flex; gap:0.5rem; align-items:center; margin-bottom:0.6rem;
    }
    .subcat-name {
        flex:1 1 auto; padding:7px 9px; border-radius:4px; border:1px solid #ccc; font-size:0.9rem;
    }
    .remove-btn {
        background:none; border:none; color:#bb0000; font-size:0.9rem; cursor:pointer; padding:0;
    }
    .remove-btn:hover { text-decoration: underline; }

    .fields-wrap { margin-top:0.5rem; }
    .field-row { display:flex; gap:0.4rem; align-items:center; margin-bottom:0.35rem; }
    .field-input { flex:1 1 auto; padding:7px 9px; border-radius:4px; border:1px solid #ccc; font-size:0.9rem; }
    .small-button {
        display:inline-block; padding:5px 10px; font-size:0.8rem; border-radius:4px; border:1px solid #ccc; background:#f7f7f7; cursor:pointer;
    }
    .small-button:hover { background:#e8e8e8; }

    .primary-btn {
        padding: 8px 16px; border-radius: 4px; border: none; background-color:#0073e6; color:#fff; font-size:0.95rem; cursor:pointer;
    }
    .primary-btn:hover { background-color:#005bb5; }

    .msg-success {
        margin-bottom: 0.9rem; padding: 0.6rem 0.8rem;
        background-color:#e0f5e9; border:1px solid #7bcf9b; color:#216b3a; border-radius:4px; font-size:0.85rem;
    }
    .msg-error {
        margin-bottom: 0.9rem; padding: 0.6rem 0.8rem;
        background-color:#fde2e0; border:1px solid #f29b96; color:#7c2520; border-radius:4px; font-size:0.85rem;
    }
</style>

<script>
    // Keep a live index for subcategory blocks so we can name fields like fieldName_<index>[]
    function nextSubcatIndex() {
        const blocks = document.querySelectorAll(".subcat-card");
        return blocks.length; // 0-based
    }

    function addSubcategory(required = false) {
        const idx = nextSubcatIndex();
        const container = document.getElementById("subcatContainer");

        const card = document.createElement("div");
        card.className = "subcat-card";
        card.dataset.index = String(idx);

        // Header row with name + remove
        const header = document.createElement("div");
        header.className = "subcat-header";

        const nameInput = document.createElement("input");
        nameInput.type = "text";
        nameInput.name = "subcatName";
        nameInput.className = "subcat-name";
        nameInput.placeholder = "Subcategory " + (idx + 1);
        if (required) nameInput.required = true;

        const removeBtn = document.createElement("button");
        removeBtn.type = "button";
        removeBtn.className = "remove-btn";
        removeBtn.textContent = "Remove";
        removeBtn.onclick = () => removeSubcategory(card);

        header.appendChild(nameInput);
        header.appendChild(removeBtn);
        card.appendChild(header);

        // Fields area for this subcategory
        const fieldsWrap = document.createElement("div");
        fieldsWrap.className = "fields-wrap";

        const fieldsTitle = document.createElement("div");
        fieldsTitle.style.fontSize = "0.9rem";
        fieldsTitle.style.fontWeight = "600";
        fieldsTitle.style.marginBottom = "0.35rem";
        fieldsTitle.textContent = "Fields (optional, for this subcategory only)";
        fieldsWrap.appendChild(fieldsTitle);

        const fieldRows = document.createElement("div");
        fieldRows.className = "field-rows";
        fieldRows.id = "fieldRows_" + idx;
        fieldsWrap.appendChild(fieldRows);

        const addFieldBtn = document.createElement("button");
        addFieldBtn.type = "button";
        addFieldBtn.className = "small-button";
        addFieldBtn.textContent = "+ Add field";
        addFieldBtn.onclick = () => addFieldRow(idx);
        fieldsWrap.appendChild(addFieldBtn);

        card.appendChild(fieldsWrap);
        container.appendChild(card);

        // Add one blank field row by default (optional)
        addFieldRow(idx, false);
        revalidateSubcatRemoveVisibility();
    }

    function addFieldRow(subcatIdx, required = false) {
        const list = document.getElementById("fieldRows_" + subcatIdx);
        if (!list) return;

        const row = document.createElement("div");
        row.className = "field-row";

        const input = document.createElement("input");
        input.type = "text";
        input.name = "fieldName_" + subcatIdx; // servlet will use getParameterValues("fieldName_<i>")
        input.className = "field-input";
        input.placeholder = "Field name (e.g., Brand, Size, Color)";
        if (required) input.required = true;

        const removeBtn = document.createElement("button");
        removeBtn.type = "button";
        removeBtn.className = "remove-btn";
        removeBtn.textContent = "Remove";
        removeBtn.onclick = () => list.removeChild(row);

        row.appendChild(input);
        row.appendChild(removeBtn);
        list.appendChild(row);
    }

    function removeSubcategory(cardEl) {
        const container = document.getElementById("subcatContainer");
        const count = container.querySelectorAll(".subcat-card").length;
        if (count <= 3) {
            alert("You must have at least 3 subcategories.");
            return;
        }
        container.removeChild(cardEl);
        reindexSubcategoryBlocks();
        revalidateSubcatRemoveVisibility();
    }

    // After removing a middle block, we reindex IDs/names for field groups so the servlet sees contiguous indices
    function reindexSubcategoryBlocks() {
        const blocks = document.querySelectorAll(".subcat-card");
        blocks.forEach((block, i) => {
            block.dataset.index = String(i);
            // update placeholder number
            const nameInput = block.querySelector(".subcat-name");
            if (nameInput && nameInput.placeholder.startsWith("Subcategory ")) {
                nameInput.placeholder = "Subcategory " + (i + 1);
            }
            // update field list id
            const fieldRows = block.querySelector(".field-rows");
            if (fieldRows) {
                fieldRows.id = "fieldRows_" + i;
                // also update each field input name to "fieldName_i"
                fieldRows.querySelectorAll("input[type=text]").forEach(inp => {
                    inp.name = "fieldName_" + i;
                });
            }
        });
    }

    function revalidateSubcatRemoveVisibility() {
        const blocks = document.querySelectorAll(".subcat-card");
        const count = blocks.length;
        blocks.forEach(block => {
            const btn = block.querySelector(".remove-btn");
            if (btn) btn.style.visibility = (count <= 3) ? "hidden" : "visible";
        });
    }

    // Initialize with 3 required subcategories
    document.addEventListener("DOMContentLoaded", () => {
        addSubcategory(true);
        addSubcategory(true);
        addSubcategory(true);
    });
</script>

        
    </main>

    <script>
        document.addEventListener("DOMContentLoaded", () => {
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
</body>
</html>
