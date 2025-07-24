<?php
// save_pose.php
header("Access-Control-Allow-Origin: *");
header('Content-Type: application/json');
require 'db_config.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['servo1']) && isset($_POST['servo2']) && isset($_POST['servo3']) && isset($_POST['servo4'])) {
        
        $s1 = intval($_POST['servo1']);
        $s2 = intval($_POST['servo2']);
        $s3 = intval($_POST['servo3']);
        $s4 = intval($_POST['servo4']);

        $stmt = $conn->prepare("INSERT INTO angles (servo1, servo2, servo3, servo4) VALUES (?, ?, ?, ?)");
        // 'iiii' means four integer parameters
        $stmt->bind_param("iiii", $s1, $s2, $s3, $s4);

        if ($stmt->execute()) {
            echo json_encode(['status' => 'success', 'message' => 'Pose saved.']);
        } else {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => 'Failed to save pose: ' . $stmt->error]);
        }
        $stmt->close();
    } else {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Missing servo parameters.']);
    }
} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Invalid request method.']);
}
$conn->close();
?>