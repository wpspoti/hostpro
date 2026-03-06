<?php
session_start();
if($_POST){
 if($_POST["user"]=="admin" && $_POST["pass"]=="123456"){
   $_SESSION["login"]=1;
   header("Location: index.php");
 }
}
?>
<form method="post">
<input name="user" placeholder="Kullanıcı"><br>
<input type="password" name="pass" placeholder="Şifre"><br>
<button>Giriş</button>
</form>
