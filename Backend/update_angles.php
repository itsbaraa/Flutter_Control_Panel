<?php
// update_angles.php
header("Access-Control-Allow-Origin: *");
header('Content-Type: application/json');

// This script writes to a file, not the database.
// This is faster for real-time polling by the ESP32.

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['servo1']) && isset($_POST['servo2']) && isset($_POST['servo3']) && isset($_POST['servo4'])) {
        
        $s1 = intval($_POST['servo1']);
        $s2 = intval($_POST['servo2']);
        $s3 = intval($_POST['servo3']);
        $s4 = intval($_POST['servo4']);

        // Format: 90,90,90,90
        $dataString = "$s1,$s2,$s3,$s4";

        // Write the string to angles.txt
        if (file_put_contents('angles.txt', $dataString) !== false) {
            echo json_encode(['status' => 'success', 'message' => 'Angles updated in file.']);
        } else {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => 'Failed to write to file.']);
        }

    } else {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Missing servo parameters.']);
    }
} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Invalid request method.']);
}
?>