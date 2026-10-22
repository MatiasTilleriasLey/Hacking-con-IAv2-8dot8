<?php
session_start();

// Diagnostics tool is gated behind the (SQLi-bypassable) login.
if (empty($_SESSION['auth'])) {
    header('Location: login.php');
    exit;
}
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Network Diagnostics</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
<div class="topbar">
    <span>Signed in as <strong><?php echo htmlspecialchars($_SESSION['user']); ?></strong></span>
    <nav>
        <a href="index.php">Diagnostics</a>
        <a href="index.php?page=pages/help.php">Help</a>
        <a href="logout.php">Sign out</a>
    </nav>
</div>
<div class="card">
    <h1>Network Diagnostics Tool</h1>
    <p class="subtitle">Check host reachability.</p>
    <form method="GET">
        <label for="host">Host</label>
        <input type="text" id="host" name="host" placeholder="127.0.0.1" value="<?php echo isset($_GET['host']) ? htmlspecialchars($_GET['host']) : ''; ?>">
        <button type="submit">Ping</button>
    </form>
<?php
// VULNERABLE BY DESIGN: unsanitized input passed to a shell. Command injection -> RCE.
if (isset($_GET['host']) && $_GET['host'] !== '') {
    $host = $_GET['host'];
    echo "<h2>Result</h2><pre>";
    system("ping -c 1 " . $host);
    echo "</pre>";
}

// VULNERABLE BY DESIGN: raw file include from user input. Local File Inclusion.
// e.g. ?page=pages/help.php (intended) or ?page=/etc/passwd (traversal).
if (isset($_GET['page']) && $_GET['page'] !== '') {
    echo "<div class='content'>";
    include $_GET['page'];
    echo "</div>";
}
?>
</div>
</body>
</html>
