CREATE DATABASE  IF NOT EXISTS `auction_site` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `auction_site`;
-- MySQL dump 10.13  Distrib 8.0.44, for Win64 (x86_64)
--
-- Host: localhost    Database: auction_site
-- ------------------------------------------------------
-- Server version	8.0.44

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `alerts`
--

DROP TABLE IF EXISTS `alerts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `alerts` (
  `alert_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `category_id` int NOT NULL,
  `subcategory_id` int NOT NULL,
  `keywords` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`alert_id`),
  KEY `user_id` (`user_id`),
  KEY `category_id` (`category_id`,`subcategory_id`),
  CONSTRAINT `alerts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `alerts_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `category` (`category_id`),
  CONSTRAINT `alerts_ibfk_3` FOREIGN KEY (`category_id`, `subcategory_id`) REFERENCES `subcategory` (`category_id`, `subcategory_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alerts`
--

LOCK TABLES `alerts` WRITE;
/*!40000 ALTER TABLE `alerts` DISABLE KEYS */;
INSERT INTO `alerts` VALUES (3,11,1,1,'Nike 10');
/*!40000 ALTER TABLE `alerts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auctions`
--

DROP TABLE IF EXISTS `auctions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auctions` (
  `auction_id` int NOT NULL AUTO_INCREMENT,
  `item_id` int NOT NULL,
  `user_id` int NOT NULL,
  `start_price` decimal(10,2) NOT NULL,
  `bid_increment` decimal(10,2) NOT NULL,
  `start_time` datetime NOT NULL,
  `end_time` datetime NOT NULL,
  `minimum_price` decimal(10,2) NOT NULL,
  `winner_id` int DEFAULT NULL,
  `final_price` decimal(10,2) DEFAULT NULL,
  `status` varchar(20) NOT NULL,
  PRIMARY KEY (`auction_id`),
  KEY `item_id` (`item_id`),
  KEY `user_id` (`user_id`),
  KEY `winner_id` (`winner_id`),
  CONSTRAINT `auctions_ibfk_1` FOREIGN KEY (`item_id`) REFERENCES `items` (`item_id`),
  CONSTRAINT `auctions_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `auctions_ibfk_3` FOREIGN KEY (`winner_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auctions`
--

LOCK TABLES `auctions` WRITE;
/*!40000 ALTER TABLE `auctions` DISABLE KEYS */;
INSERT INTO `auctions` VALUES (8,8,1,150.00,20.00,'2025-12-06 16:24:11','2025-12-06 16:28:00',300.00,NULL,NULL,'CLOSED'),(9,9,1,70.00,10.00,'2025-12-06 16:33:57','2025-12-06 16:38:00',100.00,11,160.00,'CLOSED'),(10,10,1,300.00,20.00,'2025-12-06 17:21:25','2025-12-06 17:23:00',350.00,11,350.00,'CLOSED'),(11,11,1,100.00,10.00,'2025-12-06 18:10:11','2026-02-25 14:00:00',100.00,NULL,NULL,'OPEN'),(12,12,1,100.00,10.00,'2025-12-06 18:15:47','2025-12-08 18:15:00',100.00,NULL,NULL,'REMOVED_BY_REP'),(13,13,1,100.00,10.00,'2025-12-06 18:25:50','2025-12-07 18:25:00',100.00,NULL,NULL,'REMOVED_BY_REP'),(14,14,1,200.00,10.00,'2025-12-06 18:28:33','2026-02-25 14:00:00',200.00,NULL,NULL,'OPEN'),(15,15,1,50.00,5.00,'2025-11-25 20:45:28','2025-12-01 20:45:28',40.00,11,60.00,'CLOSED'),(16,16,1,60.00,5.00,'2025-12-06 10:00:00','2026-02-10 10:00:00',50.00,NULL,NULL,'OPEN'),(17,17,1,90.00,5.00,'2025-12-06 11:00:00','2026-02-12 11:00:00',80.00,NULL,NULL,'OPEN'),(18,18,10,35.00,2.00,'2025-12-06 09:30:00','2026-02-15 09:30:00',30.00,NULL,NULL,'OPEN'),(19,19,11,600.00,10.00,'2025-12-06 08:00:00','2026-02-20 08:00:00',550.00,NULL,NULL,'OPEN'),(20,20,1,800.00,20.00,'2025-12-06 12:30:00','2026-02-18 12:30:00',700.00,NULL,NULL,'OPEN'),(21,21,12,500.00,10.00,'2025-12-06 14:00:00','2026-02-25 14:00:00',450.00,NULL,NULL,'OPEN'),(22,22,1,7000.00,100.00,'2025-12-06 09:00:00','2026-02-28 09:00:00',6500.00,NULL,NULL,'OPEN'),(23,23,10,5500.00,100.00,'2025-12-06 16:00:00','2026-02-22 16:00:00',5000.00,NULL,NULL,'OPEN'),(24,24,11,9000.00,150.00,'2025-12-06 18:00:00','2026-02-26 18:00:00',8500.00,NULL,NULL,'OPEN'),(25,25,1,80.00,5.00,'2025-10-01 10:00:00','2025-10-05 10:00:00',75.00,10,95.00,'CLOSED'),(26,26,11,150.00,10.00,'2025-09-20 09:00:00','2025-09-25 09:00:00',160.00,NULL,NULL,'CLOSED'),(27,27,10,20.00,2.00,'2025-08-10 15:00:00','2025-08-12 15:00:00',15.00,11,22.00,'CLOSED'),(28,28,11,350.00,10.00,'2025-11-01 09:00:00','2025-11-05 09:00:00',320.00,12,380.00,'CLOSED'),(29,29,1,500.00,20.00,'2025-07-01 12:00:00','2025-07-07 12:00:00',450.00,NULL,NULL,'CLOSED'),(30,30,12,200.00,5.00,'2025-06-10 08:00:00','2025-06-12 08:00:00',180.00,1,210.00,'CLOSED'),(31,31,1,9000.00,200.00,'2025-09-01 09:00:00','2025-09-10 09:00:00',8500.00,12,9400.00,'CLOSED'),(32,32,10,5500.00,100.00,'2025-08-05 16:00:00','2025-08-09 16:00:00',5300.00,NULL,NULL,'CLOSED'),(33,33,11,8000.00,150.00,'2025-05-15 13:00:00','2025-05-20 13:00:00',7500.00,1,8300.00,'CLOSED'),(34,34,1,180.00,5.00,'2025-12-06 10:00:00','2026-03-01 10:00:00',160.00,NULL,NULL,'OPEN'),(35,35,11,120.00,5.00,'2025-12-06 11:00:00','2026-03-05 11:00:00',100.00,NULL,NULL,'OPEN'),(36,36,10,500.00,10.00,'2025-12-06 12:00:00','2026-03-10 12:00:00',450.00,NULL,NULL,'OPEN'),(37,37,12,1500.00,25.00,'2025-12-06 13:00:00','2026-03-15 13:00:00',1400.00,NULL,NULL,'OPEN'),(38,38,11,400.00,10.00,'2025-12-06 14:00:00','2026-03-20 14:00:00',350.00,NULL,NULL,'OPEN'),(39,39,1,17000.00,250.00,'2025-12-06 15:00:00','2026-03-25 15:00:00',16000.00,NULL,NULL,'OPEN');
/*!40000 ALTER TABLE `auctions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `autobid`
--

DROP TABLE IF EXISTS `autobid`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `autobid` (
  `autobid_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `auction_id` int NOT NULL,
  `max_amount` decimal(10,2) NOT NULL,
  `increment` decimal(10,2) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `created_time` datetime NOT NULL,
  PRIMARY KEY (`autobid_id`),
  KEY `user_id` (`user_id`),
  KEY `auction_id` (`auction_id`),
  CONSTRAINT `autobid_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `autobid_ibfk_2` FOREIGN KEY (`auction_id`) REFERENCES `auctions` (`auction_id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `autobid`
--

LOCK TABLES `autobid` WRITE;
/*!40000 ALTER TABLE `autobid` DISABLE KEYS */;
INSERT INTO `autobid` VALUES (2,10,8,250.00,25.00,1,'2025-12-06 16:26:35'),(3,10,9,150.00,20.00,1,'2025-12-06 16:34:49'),(4,11,10,400.00,20.00,1,'2025-12-06 17:21:56');
/*!40000 ALTER TABLE `autobid` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bids`
--

DROP TABLE IF EXISTS `bids`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bids` (
  `bid_id` int NOT NULL AUTO_INCREMENT,
  `auction_id` int NOT NULL,
  `bidder_id` int NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `placed_time` datetime NOT NULL,
  PRIMARY KEY (`bid_id`),
  KEY `auction_id` (`auction_id`),
  KEY `bidder_id` (`bidder_id`),
  CONSTRAINT `bids_ibfk_1` FOREIGN KEY (`auction_id`) REFERENCES `auctions` (`auction_id`),
  CONSTRAINT `bids_ibfk_2` FOREIGN KEY (`bidder_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=74 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bids`
--

LOCK TABLES `bids` WRITE;
/*!40000 ALTER TABLE `bids` DISABLE KEYS */;
INSERT INTO `bids` VALUES (12,8,10,170.00,'2025-12-06 16:26:35'),(13,8,11,190.00,'2025-12-06 16:27:58'),(14,8,10,215.00,'2025-12-06 16:27:58'),(16,9,10,90.00,'2025-12-06 16:34:49'),(17,9,11,100.00,'2025-12-06 16:35:32'),(18,9,10,120.00,'2025-12-06 16:35:32'),(19,9,11,130.00,'2025-12-06 16:37:14'),(20,9,10,150.00,'2025-12-06 16:37:14'),(21,9,11,160.00,'2025-12-06 16:37:22'),(22,10,11,350.00,'2025-12-06 17:21:41'),(23,11,11,100.00,'2025-12-06 19:21:58'),(24,11,12,120.00,'2025-12-06 19:22:52'),(25,11,11,140.00,'2025-12-06 19:23:51'),(26,11,12,160.00,'2025-12-06 19:24:55'),(27,11,11,170.00,'2025-12-06 19:31:39'),(28,11,12,200.00,'2025-12-06 19:31:54'),(29,11,11,210.00,'2025-12-06 19:33:39'),(30,11,12,250.00,'2025-12-06 19:33:51'),(31,11,11,260.00,'2025-12-06 19:37:37'),(32,11,12,290.00,'2025-12-06 19:37:51'),(33,11,11,300.00,'2025-12-06 19:40:59'),(34,11,12,350.00,'2025-12-06 19:41:38'),(35,15,11,60.00,'2025-11-13 20:45:28'),(36,16,10,65.00,'2025-12-06 12:15:00'),(37,16,11,70.00,'2025-12-07 09:30:00'),(38,17,12,95.00,'2025-12-06 13:00:00'),(39,18,11,37.00,'2025-12-06 10:45:00'),(40,19,1,610.00,'2025-12-06 09:00:00'),(41,19,10,620.00,'2025-12-07 15:30:00'),(42,20,12,820.00,'2025-12-06 13:10:00'),(43,21,1,510.00,'2025-12-06 15:05:00'),(44,22,11,7100.00,'2025-12-07 10:20:00'),(45,23,1,5600.00,'2025-12-06 17:15:00'),(46,24,12,9100.00,'2025-12-07 08:45:00'),(47,25,10,85.00,'2025-10-02 11:15:00'),(48,25,11,90.00,'2025-10-03 09:30:00'),(49,25,10,95.00,'2025-10-03 18:45:00'),(50,26,1,145.00,'2025-09-21 12:00:00'),(51,26,12,150.00,'2025-09-22 16:30:00'),(52,27,11,22.00,'2025-08-11 10:15:00'),(53,28,1,360.00,'2025-11-02 10:00:00'),(54,28,10,370.00,'2025-11-02 18:20:00'),(55,28,12,380.00,'2025-11-03 13:45:00'),(56,30,10,205.00,'2025-06-10 12:10:00'),(57,30,1,210.00,'2025-06-11 09:30:00'),(58,31,11,9200.00,'2025-09-03 10:15:00'),(59,31,12,9400.00,'2025-09-05 14:40:00'),(60,32,1,5200.00,'2025-08-06 10:00:00'),(61,33,10,8100.00,'2025-05-16 09:45:00'),(62,33,1,8300.00,'2025-05-17 11:20:00'),(63,34,10,185.00,'2025-12-07 12:15:00'),(64,34,11,190.00,'2025-12-08 09:30:00'),(65,35,1,125.00,'2025-12-07 14:10:00'),(66,35,10,130.00,'2025-12-09 16:45:00'),(67,36,1,510.00,'2025-12-07 10:05:00'),(68,36,12,520.00,'2025-12-08 19:30:00'),(69,37,1,1525.00,'2025-12-07 11:20:00'),(70,37,11,1550.00,'2025-12-09 17:40:00'),(71,38,10,410.00,'2025-12-07 13:00:00'),(72,39,12,17100.00,'2025-12-07 16:10:00'),(73,39,11,17350.00,'2025-12-09 09:25:00');
/*!40000 ALTER TABLE `bids` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `category`
--

DROP TABLE IF EXISTS `category`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `category` (
  `category_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`category_id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `category`
--

LOCK TABLES `category` WRITE;
/*!40000 ALTER TABLE `category` DISABLE KEYS */;
INSERT INTO `category` VALUES (1,'Shoes'),(2,'Electronics'),(3,'Vehicles');
/*!40000 ALTER TABLE `category` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `customerservicetickets`
--

DROP TABLE IF EXISTS `customerservicetickets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `customerservicetickets` (
  `ticket_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `rep_id` int DEFAULT NULL,
  `subject` varchar(100) NOT NULL,
  `question_text` text NOT NULL,
  `response_text` text,
  `status` enum('OPEN','ANSWERED','CLOSED') NOT NULL DEFAULT 'OPEN',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `responded_at` datetime DEFAULT NULL,
  PRIMARY KEY (`ticket_id`),
  KEY `user_id` (`user_id`),
  KEY `rep_id` (`rep_id`),
  CONSTRAINT `customerservicetickets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `customerservicetickets_ibfk_2` FOREIGN KEY (`rep_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customerservicetickets`
--

LOCK TABLES `customerservicetickets` WRITE;
/*!40000 ALTER TABLE `customerservicetickets` DISABLE KEYS */;
INSERT INTO `customerservicetickets` VALUES (17,12,13,'Auction Question','How to make an auction?','Go to create auction tab','ANSWERED','2025-12-07 15:34:15','2025-12-07 15:34:29'),(18,26,NULL,'Issue placing bid','When I try to place a bid on an auction, I get an error message. Can you help?',NULL,'OPEN','2024-11-15 10:15:00',NULL),(19,11,NULL,'Question about automatic bidding','How does the automatic bidding feature work and how do I set a maximum?','Hi Bob, automatic bidding will place bids on your behalf in increments until your maximum is reached.','ANSWERED','2024-11-14 09:20:00','2024-11-14 10:00:00');
/*!40000 ALTER TABLE `customerservicetickets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fields`
--

DROP TABLE IF EXISTS `fields`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fields` (
  `field_id` int NOT NULL AUTO_INCREMENT,
  `category_id` int NOT NULL,
  `subcategory_id` int NOT NULL,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`field_id`,`category_id`,`subcategory_id`),
  UNIQUE KEY `uq_field_id` (`field_id`),
  KEY `category_id` (`category_id`,`subcategory_id`),
  CONSTRAINT `fields_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `category` (`category_id`),
  CONSTRAINT `fields_ibfk_2` FOREIGN KEY (`category_id`, `subcategory_id`) REFERENCES `subcategory` (`category_id`, `subcategory_id`)
) ENGINE=InnoDB AUTO_INCREMENT=75 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fields`
--

LOCK TABLES `fields` WRITE;
/*!40000 ALTER TABLE `fields` DISABLE KEYS */;
INSERT INTO `fields` VALUES (1,1,1,'Size'),(2,1,1,'Brand'),(3,1,1,'Color'),(4,1,2,'Material'),(5,1,2,'Size'),(6,1,2,'Waterproof'),(7,1,3,'Size'),(8,1,3,'Style'),(9,1,3,'Color'),(45,2,4,'Storage'),(46,2,4,'Color'),(47,2,4,'Model'),(48,2,5,'RAM'),(49,2,5,'CPU'),(50,2,5,'Storage'),(51,2,6,'Screen Size'),(52,2,6,'Storage'),(53,2,6,'Brand'),(54,3,7,'Mileage'),(55,3,7,'Year'),(56,3,7,'Make'),(57,3,7,'Model'),(58,3,8,'Engine Size'),(59,3,8,'Mileage'),(60,3,8,'Year'),(61,3,9,'Towing Capacity'),(62,3,9,'Year'),(63,3,9,'Make');
/*!40000 ALTER TABLE `fields` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `itemfieldvalues`
--

DROP TABLE IF EXISTS `itemfieldvalues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `itemfieldvalues` (
  `item_id` int NOT NULL,
  `field_id` int NOT NULL,
  `value` varchar(255) NOT NULL,
  PRIMARY KEY (`item_id`,`field_id`),
  KEY `field_id` (`field_id`),
  CONSTRAINT `itemfieldvalues_ibfk_1` FOREIGN KEY (`item_id`) REFERENCES `items` (`item_id`),
  CONSTRAINT `itemfieldvalues_ibfk_2` FOREIGN KEY (`field_id`) REFERENCES `fields` (`field_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `itemfieldvalues`
--

LOCK TABLES `itemfieldvalues` WRITE;
/*!40000 ALTER TABLE `itemfieldvalues` DISABLE KEYS */;
INSERT INTO `itemfieldvalues` VALUES (8,1,'10'),(8,2,'Nike'),(8,3,'Blue'),(9,7,'10'),(9,8,'Open'),(9,9,'Green'),(10,45,'128 gbs'),(10,46,'Black'),(10,47,'13'),(11,1,'10'),(11,2,'Nike'),(11,3,'Blue'),(12,1,'10'),(12,2,'Nike'),(12,3,'Gray'),(13,1,'10'),(13,2,'Nike'),(13,3,'Grey'),(14,1,'10'),(14,2,'Nike'),(14,3,'Blue'),(15,1,'10'),(15,2,'Nike'),(15,3,'Black/White'),(16,1,'9.5'),(16,2,'Nike'),(16,3,'Blue'),(17,4,'Leather'),(17,5,'11'),(17,6,'Yes'),(18,7,'9'),(18,8,'Arizona'),(18,9,'Brown'),(19,45,'256 GB'),(19,46,'Graphite'),(19,47,'iPhone 13 Pro'),(20,48,'16 GB'),(20,49,'Intel i7'),(20,50,'512 GB SSD'),(21,51,'11 inch'),(21,52,'256 GB'),(21,53,'Samsung'),(22,54,'85000'),(22,55,'2015'),(22,56,'Toyota'),(22,57,'Corolla'),(23,58,'689 cc'),(23,59,'12000'),(23,60,'2018'),(24,61,'10000'),(24,62,'2016'),(24,63,'Ford'),(25,1,'10.5'),(25,2,'Nike'),(25,3,'Panda Black/White'),(26,4,'Leather'),(26,5,'10'),(26,6,'No'),(27,7,'9'),(27,8,'Hiking'),(27,9,'Olive'),(28,45,'128 GB'),(28,46,'Snow'),(28,47,'Pixel 7'),(29,48,'16 GB'),(29,49,'Intel i5'),(29,50,'256 GB SSD'),(30,51,'7.9 inch'),(30,52,'64 GB'),(30,53,'Apple'),(31,54,'60000'),(31,55,'2017'),(31,56,'Honda'),(31,57,'Civic'),(32,58,'399 cc'),(32,59,'8000'),(32,60,'2020'),(33,61,'12000'),(33,62,'2014'),(33,63,'Chevrolet'),(34,1,'9'),(34,2,'New Balance'),(34,3,'Grey'),(35,4,'Nubuck Leather'),(35,5,'10.5'),(35,6,'Yes'),(36,45,'256 GB'),(36,46,'Phantom Black'),(36,47,'Galaxy S22'),(37,48,'16 GB'),(37,49,'Apple M1 Pro'),(37,50,'1 TB SSD'),(38,51,'10.9 inch'),(38,52,'256 GB'),(38,53,'Apple'),(39,54,'40000'),(39,55,'2019'),(39,56,'Toyota'),(39,57,'RAV4');
/*!40000 ALTER TABLE `itemfieldvalues` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `items`
--

DROP TABLE IF EXISTS `items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `items` (
  `item_id` int NOT NULL AUTO_INCREMENT,
  `seller_id` int NOT NULL,
  `category_id` int NOT NULL,
  `subcategory_id` int NOT NULL,
  `name` varchar(50) NOT NULL,
  `condition` varchar(50) NOT NULL,
  PRIMARY KEY (`item_id`),
  KEY `seller_id` (`seller_id`),
  KEY `category_id` (`category_id`,`subcategory_id`),
  CONSTRAINT `items_ibfk_1` FOREIGN KEY (`seller_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `items_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `category` (`category_id`),
  CONSTRAINT `items_ibfk_3` FOREIGN KEY (`category_id`, `subcategory_id`) REFERENCES `subcategory` (`category_id`, `subcategory_id`)
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `items`
--

LOCK TABLES `items` WRITE;
/*!40000 ALTER TABLE `items` DISABLE KEYS */;
INSERT INTO `items` VALUES (8,1,1,1,'Nike Shoes','New'),(9,1,1,3,'Nike Slides','New'),(10,1,2,4,'iPhone 13','New'),(11,1,1,1,'Nike Sneakers Size 10 Blue','New'),(12,1,1,1,'Nike Size 10 Gray','New'),(13,1,1,1,'Nike Shoes Size 10','New'),(14,1,1,1,'Nike Size 10 Blue','New'),(15,1,1,1,'Nike Air Zoom Pegasus 40','Used - Good'),(16,1,1,1,'Nike Air Zoom Pegasus Demo','Used - Very Good'),(17,1,1,2,'Timberland Waterproof Boots','Used - Good'),(18,10,1,3,'Birkenstock Arizona Sandals','Used - Fair'),(19,11,2,4,'Apple iPhone 13 Pro','Like New'),(20,1,2,5,'Dell XPS 13','Used - Very Good'),(21,12,2,6,'Samsung Galaxy Tab S9','Open Box'),(22,1,3,7,'Toyota Corolla 2015','Used - Good'),(23,10,3,8,'Yamaha MT-07 2018','Used - Very Good'),(24,11,3,9,'Ford F-150 2016','Used - Fair'),(25,1,1,1,'Nike Dunk Low Retro','Used - Very Good'),(26,11,1,2,'Red Wing Iron Ranger Boots','Used - Good'),(27,10,1,3,'Teva Hiking Sandals','Used - Fair'),(28,11,2,4,'Google Pixel 7','Used - Very Good'),(29,1,2,5,'Lenovo ThinkPad T480','Used - Good'),(30,12,2,6,'iPad Mini 5','Used - Good'),(31,1,3,7,'Honda Civic 2017','Used - Very Good'),(32,10,3,8,'Kawasaki Ninja 400','Used - Good'),(33,11,3,9,'Chevy Silverado 2014','Used - Fair'),(34,1,1,1,'New Balance 990v6','New - With Box'),(35,11,1,2,'Timberland 6-Inch Premium Boots','Used - Good'),(36,10,2,4,'Samsung Galaxy S22','Used - Very Good'),(37,12,2,5,'MacBook Pro 14 2021 (M1 Pro)','Used - Excellent'),(38,11,2,6,'iPad Air 4','Used - Good'),(39,1,3,7,'Toyota RAV4 2019','Used - Very Good');
/*!40000 ALTER TABLE `items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `notif_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `message` varchar(255) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_read` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`notif_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
INSERT INTO `notifications` VALUES (1,11,'? Congratulations! You won auction #10 with a final bid of $350.00','2025-12-06 17:23:26',1),(2,1,'Your auction #10 has ended with a winning bid of $350.00','2025-12-06 17:23:26',1),(3,11,'A new auction (#13) has been created for an item matching your alert: Nike Shoes Size 10 (keywords: Nike 10)','2025-12-06 18:25:49',1),(4,11,'A new auction (#14) has been created for an item matching your alert: Nike Size 10 Blue (keywords: Nike 10)<br><a href=\"placeBid.jsp?auctionId=14\">View &amp; Place a Bid</a>','2025-12-06 18:28:33',1),(5,11,'You have been outbid on auction #11. Your previous highest bid was $140.00. The new bid is $160.<br><a href=\"placeBid.jsp?auctionId=11\">View auction and place a higher bid</a>','2025-12-06 19:24:55',1),(6,1,'Your auction #11 received a new bid of $160.<br><a href=\"viewAuction.jsp?auctionId=11\">View auction details</a>','2025-12-06 19:24:55',1),(7,11,'You have been outbid on auction #11. Your previous highest bid was $170.00. The new bid is $200.<br><a href=\"placeBid.jsp?auctionId=11\">View auction and place a higher bid</a>','2025-12-06 19:31:54',1),(8,1,'Your auction #11 received a new bid of $200.<br><a href=\"viewAuction.jsp?auctionId=11\">View auction details</a>','2025-12-06 19:31:54',1),(9,11,'You have been outbid on auction #11. Your previous highest bid was $210.00. The new bid is $250.<br><a href=\"placeBid.jsp?auctionId=11\">View auction and place a higher bid</a>','2025-12-06 19:33:52',1),(10,1,'Your auction #11 received a new bid of $250.<br><a href=\"viewAuction.jsp?auctionId=11\">View auction details</a>','2025-12-06 19:33:52',1),(11,11,'Your automatic bidding on auction #11 has reached your maximum of $270.00 and is no longer active. The current highest bid is $290.00.<br><a href=\"placeBid.jsp?auctionId=11\">View this auction and place a manual bid</a>','2025-12-06 19:37:51',1),(12,11,'You have been outbid on auction #11. Your previous highest bid was $260.00. The new bid is $290.<br><a href=\"placeBid.jsp?auctionId=11\">View auction and place a higher bid</a>','2025-12-06 19:37:51',1),(13,1,'Your auction #11 received a new bid of $290.<br><a href=\"viewAuction.jsp?auctionId=11\">View auction details</a>','2025-12-06 19:37:51',1),(14,11,'Your automatic bidding on auction #11 has reached your maximum of $330.00 and is no longer active. The current highest bid is $350.00.<br><a href=\"placeBid.jsp?auctionId=11\">View this auction and place a manual bid</a>','2025-12-06 19:41:38',1),(15,11,'You have been outbid on auction #11. Your previous highest bid was $300.00. The new bid is $350.<br><a href=\"placeBid.jsp?auctionId=11\">View auction and place a higher bid</a>','2025-12-06 19:41:38',1),(16,1,'Your auction #11 received a new bid of $350.<br><a href=\"viewAuction.jsp?auctionId=11\">View auction details</a>','2025-12-06 19:41:38',1),(17,1,'Your support ticket #1 (\"Test\") has been answered.<br><a href=\"myTickets.jsp\">View your support tickets</a>','2025-12-06 22:52:08',1),(18,12,'Your support ticket #17 (\"Auction Question\") has been answered.<br><a href=\"myTickets.jsp\">View your support tickets</a>','2025-12-07 15:34:29',1);
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `subcategory`
--

DROP TABLE IF EXISTS `subcategory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `subcategory` (
  `subcategory_id` int NOT NULL AUTO_INCREMENT,
  `category_id` int NOT NULL,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`subcategory_id`),
  KEY `category_id` (`category_id`),
  CONSTRAINT `subcategory_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `category` (`category_id`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subcategory`
--

LOCK TABLES `subcategory` WRITE;
/*!40000 ALTER TABLE `subcategory` DISABLE KEYS */;
INSERT INTO `subcategory` VALUES (1,1,'Sneakers'),(2,1,'Boots'),(3,1,'Sandals'),(4,2,'Phones'),(5,2,'Laptops'),(6,2,'Tablets'),(7,3,'Cars'),(8,3,'Motorcycles'),(9,3,'Trucks');
/*!40000 ALTER TABLE `subcategory` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `password` varchar(50) NOT NULL,
  `email` varchar(50) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `isAnonymous` tinyint(1) NOT NULL DEFAULT '0',
  `role` enum('EndUser','Admin','CustomerRepresentative') NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `unique_email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'1234','eric@example.com','Eric','Cheung',0,'EndUser',1),(2,'1234','admin@gmail.com','John','Doe',0,'Admin',1),(10,'1234','test@gmail.com','Test','Name',0,'EndUser',1),(11,'1234','bob@gmail.com','Bob','Jones',0,'EndUser',1),(12,'1234','John@gmail.com','John','Smith',0,'EndUser',1),(13,'1234','customerrep@gmail.com','Steve','K',0,'CustomerRepresentative',1),(16,'1234','eric@rep','Eric','C',0,'CustomerRepresentative',1),(17,'1234','bill@gmail.com','Bill','Gates',0,'EndUser',1),(18,'1234','lebron@gmail.com','Lebron','James',0,'EndUser',1),(19,'1234','justin@gmail.com','Justin','Tims',0,'EndUser',1),(26,'pass123','eric@gmail.com','Eric','Cheung',0,'EndUser',1);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-12-07 19:32:37
