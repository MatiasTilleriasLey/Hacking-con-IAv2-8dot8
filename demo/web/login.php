<?php
session_start();

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';

    $db = new SQLite3('/var/www/app.db', SQLITE3_OPEN_READONLY);

    // VULNERABLE BY DESIGN: user input concatenated straight into the query.
    // SQL injection -> authentication bypass (e.g. username: admin'-- ).
    $sql = "SELECT username FROM users WHERE username = '$username' AND password = '$password'";
    $res = $db->query($sql);

    if ($res === false) {
        // Error-based feedback leaks the query shape (helps SQLi discovery).
        $error = 'SQL error: ' . $db->lastErrorMsg();
    } elseif ($row = $res->fetchArray(SQLITE3_ASSOC)) {
        $_SESSION['auth'] = true;
        $_SESSION['user'] = $row['username'];
        header('Location: index.php');
        exit;
    } else {
        $error = 'Invalid credentials.';
    }
}
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Login — Network Diagnostics</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
<div class="card">
    <h1>Network Diagnostics</h1>
    <p class="subtitle">Staff access only. Please sign in.</p>
    <?php if ($error !== ''): ?>
        <div class="error"><?php echo htmlspecialchars($error); ?></div>
    <?php endif; ?>
    <form method="POST">
        <label for="username">Username</label>
        <input type="text" id="username" name="username" autocomplete="off" autofocus>
        <label for="password">Password</label>
        <input type="password" id="password" name="password" autocomplete="off">
        <button type="submit">Sign in</button>
    </form>
</div>
</body>
</html>
