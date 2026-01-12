admin credentials:

email: admin@gmail.com  

password: 1234

---

customer representative credentials:

email: customerrep@gmail.com

password: 1234


---

enduser credentails (more in database):

email: bob@gmail.com password: 1234

email: john@gmail.com password: 1234

---

Logging in with the admin credentials will immediately direct you to the admin dashboard. 

Logging in with the customer representative credentials will immediately direct you to the customer representative dashboard.

In order to run the project locally, you will need to update the database connection settings in ApplicationDB.java. The getConnection() method is currently configured to use our local MySQL credentials.

Change the username and password on this line of code to your own MySQL credentials in ApplicationDB.java:
connection = DriverManager.getConnection(connectionUrl, "root", "cs336project");

You will also need to import our database schema. We have exported our database in the CS336_Project.sql file which is a part of the canvas submission.
