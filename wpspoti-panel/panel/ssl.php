<?php
if($_POST){
 system("certbot --nginx -d ".$_POST["domain"]);
 echo "SSL kuruldu";
}
?>
<form method="post">
<input name="domain" placeholder="domain.com">
<button>SSL Kur</button>
</form>
