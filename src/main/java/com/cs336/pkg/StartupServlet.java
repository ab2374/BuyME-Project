package com.cs336.pkg;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;

@WebServlet(value="/StartupServlet", loadOnStartup=1)
public class StartupServlet extends HttpServlet {

    @Override
    public void init() throws ServletException {
        super.init();
        System.out.println("Starting Auction Scheduler...");
        AuctionScheduler.start();
    }

    @Override
    public void destroy() {
        System.out.println("Stopping Auction Scheduler...");
        AuctionScheduler.stop();
        super.destroy();
    }
}
