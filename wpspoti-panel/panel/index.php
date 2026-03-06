<?php
session_start();
if(!isset($_SESSION["login"])) {
  header("Location: login.php"); exit;
}
?>
<h1>Wpspoti Panel</h1>
<a href="ssl.php">SSL</a> |
<a href="sites.php">Siteler</a> |
<a href="firewall.php">Firewall</a> |
<a href="logout.php">Çıkış</a>
