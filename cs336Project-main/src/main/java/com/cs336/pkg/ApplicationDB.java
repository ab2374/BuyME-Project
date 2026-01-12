package com.cs336.pkg;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class ApplicationDB {
	
	public ApplicationDB(){
		
	}

	public Connection getConnection() {
		String connectionUrl = "jdbc:mysql://localhost:3306/auction_site?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";

	    Connection connection = null;

	    try {
	        Class.forName("com.mysql.jdbc.Driver").newInstance();
	        System.out.println("✅ MySQL JDBC driver loaded successfully.");
	    } catch (Exception e) {
	        System.out.println("❌ Failed to load MySQL JDBC driver:");
	        e.printStackTrace();
	    }

	    try {
	        connection = DriverManager.getConnection(connectionUrl, "root", "cs336project");
	        System.out.println("✅ Database connection established: " + connectionUrl);
	    } catch (SQLException e) {
	        System.out.println("❌ Database connection failed:");
	        e.printStackTrace();
	    }

	    return connection;
	}

	
	public void closeConnection(Connection connection){
		try {
			connection.close();
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
	
	
	
	
	public static void main(String[] args) {
		ApplicationDB dao = new ApplicationDB();
		Connection connection = dao.getConnection();
		
		System.out.println(connection);		
		dao.closeConnection(connection);
	}
	
	

}
