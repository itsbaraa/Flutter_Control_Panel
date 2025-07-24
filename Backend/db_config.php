<?php
header("Access-Control-Allow-Origin: *"); 
// db_config.php
$dbHost = 'localhost';
$dbUser = 'root';
$dbPass = ''; // Default empty password for XAMPP
$dbName = 'servo';

$conn = new mysqli($dbHost, $dbUser, $dbPass, $dbName);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>