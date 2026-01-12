<%@ page import="jakarta.servlet.http.*,java.sql.*,com.cs336.pkg.ApplicationDB,java.util.*"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"%>

<%
    // Redirect if not logged in
    if (session == null || session.getAttribute("email") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String email     = (String) session.getAttribute("email");
    String firstName = (String) session.getAttribute("first_name");
    String lastName  = (String) session.getAttribute("last_name");
    Integer userId   = (Integer) session.getAttribute("user_id");

    ApplicationDB db = new ApplicationDB();
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    // Read search / sort parameters
    String categoryParam    = request.getParameter("category_id");
    String subcategoryParam = request.getParameter("subcategory_id");
    String qParam           = request.getParameter("q");          // keywords
    String minPriceParam    = request.getParameter("min_price");
    String maxPriceParam    = request.getParameter("max_price");
    String sortParam        = request.getParameter("sort");
%>

<!DOCTYPE html>
<html>
<head>
    <title>Home</title>

    <style>
        body {
            margin: 0;
            font-family: Arial, sans-serif;
        }

        main {
            padding: 1.5rem;
        }

        .search-box {
            margin-bottom: 1rem;
            padding: 1rem;
            border: 1px solid #ddd;
            border-radius: 6px;
            background-color: #fafafa;
            font-size: 0.9rem;
        }

        .search-row {
            display: flex;
            flex-wrap: wrap;
            gap: 0.75rem 1.5rem;
            align-items: center;
            margin-bottom: 0.5rem;
        }

        .search-row label {
            font-weight: bold;
            margin-right: 4px;
        }

        .search-row select,
        .search-row input[type="text"] {
            padding: 3px 6px;
            font-size: 0.9rem;
            min-width: 140px;
        }

        .search-actions {
            margin-top: 0.5rem;
        }

        .search-actions button,
        .search-actions a {
            padding: 0.3rem 0.8rem;
            border-radius: 4px;
            border: 1px solid #ccc;
            font-size: 0.9rem;
            text-decoration: none;
            cursor: pointer;
            background-color: white;
            color: #333;
        }

        .search-actions button:hover,
        .search-actions a:hover {
            background-color: #e6e6e6;
        }

        table {
            border-collapse: collapse;
            width: 100%;
            margin-top: 1rem;
        }

        th, td {
            border: 1px solid #ddd;
            padding: 8px 10px;
            text-align: left;
            font-size: 0.9rem;
        }

        th {
            background-color: #f5f5f5;
        }

        tr:nth-child(even) {
            background-color: #fafafa;
        }

        .no-auctions {
            margin-top: 1rem;
            font-style: italic;
        }

        .bid-button {
            display: inline-block;
            padding: 5px 10px;
            background-color: #0073e6;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            font-size: 0.85rem;
        }

        .bid-button:hover {
            background-color: #005bb5;
        }

        .own-auction-label {
            font-size: 0.85rem;
            font-weight: bold;
            color: #555;
        }

        .info-box {
            background-color: #ffe8e8;
            border: 1px solid #ffaaaa;
            color: #b00000;
            padding: 8px 12px;
            margin-bottom: 12px;
            border-radius: 4px;
            font-size: 0.9rem;
        }
    </style>
</head>

<body>

    <!-- Include navbar -->
    <jsp:include page="navbar.jsp" />

    <main>

        <!-- Auction closed message (if redirected with flag) -->
        <%
            String closedFlag = request.getParameter("auctionClosed");
            if ("1".equals(closedFlag)) {
        %>
            <div class="info-box">
                That auction is closed. You can no longer place bids on it.
            </div>
        <%
            }
        %>

        <!-- Search / browse form -->
        <div class="search-box">
            <form method="get" action="home.jsp">
                <div class="search-row">
                    <div>
                        <label for="category_id">Category:</label>
                        <select name="category_id" id="category_id">
                            <option value="">Select a category</option>
                            <%
                                // Load categories for the dropdown
                                Connection connCat = null;
                                PreparedStatement psCat = null;
                                ResultSet rsCat = null;
                                try {
                                    connCat = db.getConnection();
                                    psCat = connCat.prepareStatement(
                                        "SELECT category_id, name FROM Category ORDER BY name"
                                    );
                                    rsCat = psCat.executeQuery();
                                    while (rsCat.next()) {
                                        int cid = rsCat.getInt("category_id");
                                        String cname = rsCat.getString("name");
                                        String selected = (categoryParam != null && categoryParam.equals(String.valueOf(cid)))
                                                ? "selected"
                                                : "";
                            %>
                                <option value="<%= cid %>" <%= selected %>><%= cname %></option>
                            <%
                                    }
                                } catch (Exception e) {
                                    out.println("<option disabled>Error loading categories</option>");
                                    e.printStackTrace();
                                } finally {
                                    if (rsCat != null) try { rsCat.close(); } catch (Exception ignore) {}
                                    if (psCat != null) try { psCat.close(); } catch (Exception ignore) {}
                                    if (connCat != null) try { connCat.close(); } catch (Exception ignore) {}
                                }
                            %>
                        </select>
                    </div>

                    <div>
                        <label for="subcategory_id">Subcategory:</label>
                        <select name="subcategory_id" id="subcategory_id">
                            <option value="">Any</option>
                            <%
                                // Load ALL subcategories, then filter in JS
                                Connection connSub = null;
                                PreparedStatement psSub = null;
                                ResultSet rsSub = null;
                                try {
                                    connSub = db.getConnection();
                                    psSub = connSub.prepareStatement(
                                        "SELECT s.subcategory_id, s.name AS sub_name, " +
                                        "       s.category_id, c.name AS category_name " +
                                        "FROM Subcategory s " +
                                        "JOIN Category c ON s.category_id = c.category_id " +
                                        "ORDER BY c.name, s.name"
                                    );
                                    rsSub = psSub.executeQuery();
                                    while (rsSub.next()) {
                                        int sid = rsSub.getInt("subcategory_id");
                                        int parentCatId = rsSub.getInt("category_id");
                                        String sname = rsSub.getString("sub_name");
                                        String cname = rsSub.getString("category_name");
                                        String selected = (subcategoryParam != null &&
                                                           subcategoryParam.equals(String.valueOf(sid)))
                                                ? "selected"
                                                : "";
                            %>
                                <option value="<%= sid %>"
                                        data-category-id="<%= parentCatId %>"
                                        <%= selected %>>
                                    <%= cname %> &raquo; <%= sname %>
                                </option>
                            <%
                                    }
                                } catch (Exception e) {
                                    out.println("<option disabled>Error loading subcategories</option>");
                                    e.printStackTrace();
                                } finally {
                                    if (rsSub != null) try { rsSub.close(); } catch (Exception ignore) {}
                                    if (psSub != null) try { psSub.close(); } catch (Exception ignore) {}
                                    if (connSub != null) try { connSub.close(); } catch (Exception ignore) {}
                                }
                            %>
                        </select>
                    </div>

                    <div>
                        <label for="q">Keywords:</label>
                        <input type="text" name="q" id="q"
                               value="<%= (qParam != null ? qParam : "") %>"
                               placeholder="e.g. Nike, coat, gray">
                    </div>
                </div>

                <div class="search-row">
                    <div>
                        <label for="min_price">Min Price:</label>
                        <input type="text" name="min_price" id="min_price"
                               value="<%= (minPriceParam != null ? minPriceParam : "") %>">
                    </div>

                    <div>
                        <label for="max_price">Max Price:</label>
                        <input type="text" name="max_price" id="max_price"
                               value="<%= (maxPriceParam != null ? maxPriceParam : "") %>">
                    </div>

                    <div>
                        <label for="sort">Sort by:</label>
                        <select name="sort" id="sort">
                            <option value="endSoon" <%= ("endSoon".equals(sortParam) || sortParam == null) ? "selected" : "" %>>
                                Ending soon
                            </option>
                            <option value="priceAsc" <%= "priceAsc".equals(sortParam) ? "selected" : "" %>>
                                Price (low → high)
                            </option>
                            <option value="priceDesc" <%= "priceDesc".equals(sortParam) ? "selected" : "" %>>
                                Price (high → low)
                            </option>
                            <option value="type" <%= "type".equals(sortParam) ? "selected" : "" %>>
                                Category / Subcategory
                            </option>
                            <option value="newest" <%= "newest".equals(sortParam) ? "selected" : "" %>>
                                Newest (recently added)
                            </option>
                            <option value="oldest" <%= "oldest".equals(sortParam) ? "selected" : "" %>>
                                Oldest
                            </option>
                        </select>
                    </div>
                </div>

                <div class="search-actions">
                    <button type="submit">Search</button>
                    <a href="home.jsp">Reset</a>
                </div>
            </form>
        </div>

        <h2>Active Auctions</h2>

        <%
            try {
                conn = db.getConnection();

                // Build dynamic SQL for search + sort
                StringBuilder sql = new StringBuilder(
                    "SELECT a.auction_id, " +
                    "       a.user_id AS seller_id, " +
                    "       i.name AS item_name, " +
                    "       c.name AS category_name, " +
                    "       s.name AS subcategory_name, " +
                    "       a.start_price, " +
                    "       a.minimum_price, " +
                    "       a.start_time, " +
                    "       a.end_time, " +
                    "       (SELECT MAX(b.amount) FROM Bids b WHERE b.auction_id = a.auction_id) AS highest_bid, " +
                    "       COALESCE((SELECT MAX(b2.amount) FROM Bids b2 WHERE b2.auction_id = a.auction_id), a.start_price) AS current_price " +
                    "FROM Auctions a " +
                    "JOIN Items i ON a.item_id = i.item_id " +
                    "JOIN Category c ON i.category_id = c.category_id " +
                    "JOIN Subcategory s ON i.category_id = s.category_id AND i.subcategory_id = s.subcategory_id " +
                    "WHERE a.status = 'OPEN'"
                );

                List<Object> params = new ArrayList<>();

                // Category filter
                if (categoryParam != null && !categoryParam.isEmpty()) {
                    sql.append(" AND i.category_id = ?");
                    params.add(Integer.parseInt(categoryParam));
                }

                // Subcategory filter
                if (subcategoryParam != null && !subcategoryParam.isEmpty()) {
                    sql.append(" AND i.subcategory_id = ?");
                    params.add(Integer.parseInt(subcategoryParam));
                }

                // Keyword filter on item name
                if (qParam != null && !qParam.trim().isEmpty()) {
                    sql.append(" AND i.name LIKE ?");
                    params.add("%" + qParam.trim() + "%");
                }

                // Min price & max price filters on current_price
                java.math.BigDecimal minPriceVal = null;
                java.math.BigDecimal maxPriceVal = null;

                if (minPriceParam != null && !minPriceParam.trim().isEmpty()) {
                    try {
                        minPriceVal = new java.math.BigDecimal(minPriceParam.trim());
                    } catch (NumberFormatException ignore) {
                        // invalid input -> ignore this filter
                    }
                }

                if (maxPriceParam != null && !maxPriceParam.trim().isEmpty()) {
                    try {
                        maxPriceVal = new java.math.BigDecimal(maxPriceParam.trim());
                    } catch (NumberFormatException ignore) {
                        // invalid input -> ignore
                    }
                }

                if (minPriceVal != null) {
                    sql.append(" AND COALESCE((SELECT MAX(b.amount) FROM Bids b WHERE b.auction_id = a.auction_id), a.start_price) >= ?");
                    params.add(minPriceVal);
                }

                if (maxPriceVal != null) {
                    sql.append(" AND COALESCE((SELECT MAX(b.amount) FROM Bids b WHERE b.auction_id = a.auction_id), a.start_price) <= ?");
                    params.add(maxPriceVal);
                }

                // Sorting
                String orderBy;
                if ("priceAsc".equals(sortParam)) {
                    orderBy = "current_price ASC";
                } else if ("priceDesc".equals(sortParam)) {
                    orderBy = "current_price DESC";
                } else if ("type".equals(sortParam)) {
                    orderBy = "category_name ASC, subcategory_name ASC, item_name ASC";
                } else if ("newest".equals(sortParam)) {
                    orderBy = "a.start_time DESC";
                } else if ("oldest".equals(sortParam)) {
                    orderBy = "a.start_time ASC";
                } else {
                    // default / "endSoon"
                    orderBy = "a.end_time ASC";
                }

                sql.append(" ORDER BY ").append(orderBy);

                ps = conn.prepareStatement(sql.toString());

                // Bind params
                int idx = 1;
                for (Object p : params) {
                    if (p instanceof Integer) {
                        ps.setInt(idx++, (Integer) p);
                    } else if (p instanceof java.math.BigDecimal) {
                        ps.setBigDecimal(idx++, (java.math.BigDecimal) p);
                    } else if (p instanceof String) {
                        ps.setString(idx++, (String) p);
                    }
                }

                rs = ps.executeQuery();

                if (!rs.isBeforeFirst()) {
        %>

            <p class="no-auctions">No active auctions match your search.</p>

        <%
                } else {
        %>

        <table>
            <thead>
                <tr>
                    <th>Auction ID</th>
                    <th>Item</th>
                    <th>Category</th>
                    <th>Subcategory</th>
                    <th>Start Price ($)</th>
                    <th>Highest Bid ($)</th>
                    <th>End Time</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>

        <%
                    while (rs.next()) {
                        int auctionId  = rs.getInt("auction_id");
                        int sellerId   = rs.getInt("seller_id");
                        String itemName = rs.getString("item_name");
                        String catName  = rs.getString("category_name");
                        String subName  = rs.getString("subcategory_name");
                        java.math.BigDecimal startPrice = rs.getBigDecimal("start_price");
                        java.math.BigDecimal highestBid = rs.getBigDecimal("highest_bid");
                        Timestamp endTime   = rs.getTimestamp("end_time");
        %>

                <tr>
                    <td><%= auctionId %></td>
                    <td><%= itemName %></td>
                    <td><%= catName %></td>
                    <td><%= subName %></td>
                    <td><%= startPrice != null ? startPrice.toPlainString() : "—" %></td>
                    <td><%= (highestBid != null ? highestBid.toPlainString() : "—") %></td>
                    <td><%= endTime %></td>
                    <td>
                        <%
                            if (sellerId == userId) {
                        %>
                            <span class="own-auction-label">Your auction</span>
                        <%
                            } else {
                        %>
                            <a href="placeBid.jsp?auctionId=<%= auctionId %>" class="bid-button">
                                Place Bid
                            </a>
                        <%
                            }
                        %>
                    </td>
                </tr>

        <%
                    } // end while
        %>

            </tbody>
        </table>

        <%
                } // end else showing table
            } catch (Exception e) {
                out.println("<p style='color:red;'>Error loading auctions: " + e.getMessage() + "</p>");
                e.printStackTrace();
            } finally {
                if (rs != null) try { rs.close(); } catch (Exception ignore) {}
                if (ps != null) try { ps.close(); } catch (Exception ignore) {}
                if (conn != null) try { conn.close(); } catch (Exception ignore) {}
            }
        %>

    </main>

    <script>
        // Dependent dropdown: subcategories filtered by selected category
        document.addEventListener("DOMContentLoaded", function () {
            const categorySelect = document.getElementById("category_id");
            const subcategorySelect = document.getElementById("subcategory_id");

            // Cache all subcategory options except the first "Any"
            const allSubOptions = Array.from(subcategorySelect.options).filter(opt => opt.value !== "");

            function updateSubcategories() {
                const catVal = categorySelect.value;

                if (!catVal) {
                    // No category selected: disable and hide all specific subcategories
                    subcategorySelect.disabled = true;
                    subcategorySelect.value = "";
                    allSubOptions.forEach(opt => {
                        opt.style.display = "none";
                    });
                    return;
                }

                // Category selected: enable subcategory dropdown
                subcategorySelect.disabled = false;

                allSubOptions.forEach(opt => {
                    const optCatId = opt.getAttribute("data-category-id");
                    if (optCatId === catVal) {
                        opt.style.display = "";
                    } else {
                        if (opt.selected) {
                            opt.selected = false;
                        }
                        opt.style.display = "none";
                    }
                });

                // Reset to "Any" if current selection is hidden
                const selectedOpt = subcategorySelect.options[subcategorySelect.selectedIndex];
                if (selectedOpt && selectedOpt.style.display === "none") {
                    subcategorySelect.value = "";
                }
            }

            // Initial state
            updateSubcategories();

            // When user changes category, update subs
            categorySelect.addEventListener("change", updateSubcategories);
        });
    </script>
</body>
</html>
