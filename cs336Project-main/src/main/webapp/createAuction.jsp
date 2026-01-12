<%@ page import="jakarta.servlet.http.*,java.sql.*,com.cs336.pkg.ApplicationDB" %>

<%
    // Require login
    if (session == null || session.getAttribute("email") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String firstName = (String) session.getAttribute("first_name");
    String lastName  = (String) session.getAttribute("last_name");
    Integer userId   = (Integer) session.getAttribute("user_id");

    // Load categories from DB
    java.util.List<Integer> catIds = new java.util.ArrayList<>();
    java.util.List<String>  catNames = new java.util.ArrayList<>();

    ApplicationDB db = new ApplicationDB();
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = db.getConnection();
        ps = conn.prepareStatement("SELECT category_id, name FROM Category ORDER BY name");
        rs = ps.executeQuery();

        while (rs.next()) {
            catIds.add(rs.getInt("category_id"));
            catNames.add(rs.getString("name"));
        }

    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (rs   != null) try { rs.close(); } catch (Exception ignore) {}
        if (ps   != null) try { ps.close(); } catch (Exception ignore) {}
        if (conn != null) try { conn.close(); } catch (Exception ignore) {}
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Create Auction</title>

    <style>
        body {
            margin: 0;
            font-family: Arial, sans-serif;
        }

        main {
            padding: 1.5rem;
        }

        form {
            max-width: 500px;
            padding: 1rem 1.25rem;
            border: 1px solid #ddd;
            border-radius: 8px;
            background: #fafafa;
        }

        label {
            display: block;
            margin-top: 10px;
        }

        input, select {
            width: 100%;
            padding: 6px;
            margin-top: 4px;
            box-sizing: border-box;
        }

        button {
            margin-top: 15px;
            padding: 8px 16px;
            cursor: pointer;
        }

        #dynamicFields label {
            margin-top: 8px;
        }

        .hint-text {
            font-size: 0.85rem;
            color: #666;
            margin-top: 4px;
        }
    </style>

    <script>
        // Load subcategories when category changes
        function loadSubcategories() {
            const categoryId = document.getElementById("categorySelect").value;
            const subSelect   = document.getElementById("subcategorySelect");
            const fieldsDiv   = document.getElementById("dynamicFields");

            if (!categoryId) {
                subSelect.innerHTML = '<option value="">-- Select Subcategory --</option>';
                subSelect.disabled = true;
                fieldsDiv.innerHTML = '';
                return;
            }

            subSelect.disabled = false;

            fetch('getSubcategories?categoryId=' + encodeURIComponent(categoryId))
                .then(res => res.text())
                .then(html => {
                    subSelect.innerHTML = html;
                    fieldsDiv.innerHTML = '';
                })
                .catch(console.error);
        }

        // Load dynamic fields when subcategory changes
        function loadFields() {
            const categoryId    = document.getElementById("categorySelect").value;
            const subcategoryId = document.getElementById("subcategorySelect").value;
            const fieldsDiv     = document.getElementById("dynamicFields");

            if (!categoryId || !subcategoryId) {
                fieldsDiv.innerHTML = '';
                return;
            }

            fetch('getFields?categoryId=' + encodeURIComponent(categoryId)
                    + '&subcategoryId=' + encodeURIComponent(subcategoryId))
                .then(res => res.text())
                .then(html => {
                    fieldsDiv.innerHTML = html;
                })
                .catch(console.error);
        }
    </script>
</head>

<body>

    <!-- Include navbar -->
    <jsp:include page="navbar.jsp" />

    <main>
        <h2>Create New Auction</h2>

        <form action="CreateAuctionServlet" method="post">
            <!-- seller ID -->
            <input type="hidden" name="user_id" value="<%= userId %>">

            <label>Item Name:</label>
            <input type="text" name="item_name" required>

            <label>Category:</label>
            <select id="categorySelect" name="category_id" onchange="loadSubcategories()" required>
                <option value="">-- Select Category --</option>
                <%
                    for (int i = 0; i < catIds.size(); i++) {
                %>
                    <option value="<%= catIds.get(i) %>"><%= catNames.get(i) %></option>
                <%
                    }
                %>
            </select>

            <label>Subcategory:</label>
            <select id="subcategorySelect" name="subcategory_id" onchange="loadFields()" required disabled>
                <option value="">-- Select Subcategory --</option>
            </select>

            <!-- dynamic fields inserted here -->
            <div id="dynamicFields"></div>

            <label>Condition:</label>
            <input type="text" name="condition" required>

            <label>Start Price ($):</label>
            <input
                type="number"
                name="start_price"
                step="0.01"
                min="0.01"
                inputmode="decimal"
                required
            >

            <label>Bid Increment ($):</label>
            <input
                type="number"
                name="bid_increment"
                step="0.01"
                min="0.01"
                inputmode="decimal"
                required
            >

            <label>Minimum Price ($):</label>
            <input
                type="number"
                name="minimum_price"
                step="0.01"
                min="0.01"
                inputmode="decimal"
                required
            >

            <!-- No start_time field: it will be set to NOW on the server -->
            <label>End Time:</label>
            <input type="datetime-local" name="end_time" required>
            <p class="hint-text">
                Start time will be set to the current time automatically when you create the auction.
            </p>

            <button type="submit">Create Auction</button>
        </form>
    </main>

</body>
</html>
