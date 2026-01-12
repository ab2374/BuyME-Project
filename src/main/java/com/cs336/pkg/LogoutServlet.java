package com.cs336.pkg;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.*;

@WebServlet("/logout")
public class LogoutServlet extends HttpServlet {
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // End the current session
        HttpSession session = req.getSession(false);
        if (session != null) {
            session.invalidate();
            System.out.println("✅ Session invalidated — user logged out.");
        }

        // Redirect straight back to login.jsp
        resp.sendRedirect("login.jsp");
    }
}
