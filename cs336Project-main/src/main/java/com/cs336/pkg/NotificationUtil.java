package com.cs336.pkg;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class NotificationUtil {

    /**
     * Create a notification for a user.
     * Example message: "Congratulations! You won auction #12"
     */
    public static void createNotification(int userId, String message) throws SQLException {
        ApplicationDB db = new ApplicationDB();
        try (Connection conn = db.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "INSERT INTO Notifications(user_id, message) VALUES (?, ?)"
             )) {
            ps.setInt(1, userId);
            ps.setString(2, message);
            ps.executeUpdate();
        }
    }
}
