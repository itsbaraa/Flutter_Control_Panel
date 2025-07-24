<?php
// get_poses.php
header("Access-Control-Allow-Origin: *");
header('Content-Type: application/json');
require 'db_config.php';

$sql = "SELECT id, servo1, servo2, servo3, servo4 FROM angles ORDER BY id DESC";
$result = $conn->query($sql);

$poses = [];

if ($result->num_rows > 0) {
    // Fetch all rows into an associative array
    $poses = $result->fetch_all(MYSQLI_ASSOC);
}

echo json_encode($poses);

$conn->close();
?>