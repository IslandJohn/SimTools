<?php
// Random Weather (Server) 1.3.0
// E-mail: pilotjohn at gearsdown.com

$pdlen = 1024; // expected post data length
$fnlen = 3; // file name length 
$pdata = file_get_contents("php://input");

if (strlen($pdata) == $pdlen) {
	$tries = pow(36, $fnlen);
	
	do {
		$fname = strtoupper(base_convert(rand(pow(36, $fnlen-1), pow(36, $fnlen)-1), 10, 36));
		$tries = $tries - 1;
	} while ($tries > 0 and file_exists($fname) and time()-3600 < filemtime($fname));
	
	if ($tries > 0 and file_put_contents($fname, $pdata) == strlen($pdata)) {
		print($fname);
	}
}
?>