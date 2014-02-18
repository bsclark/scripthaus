<?PHP
$csvFile_dir = "C:\<some dir>\<some file>.csv";
$csvFile_files = "C:\<some dir>\<some file>.csv";

$start_dir = "S:";
$dir_list = array();	# Array to store directories that are old
$file_list = array();	# Array to store files that are old

$timer = time() - (3600 * 24 * 365);

dir_parse( $start_dir, $dir_list, $file_list );
unset( $d, $f );

$fhandle = fopen( $csvFile_dir, 'w+' );
fputcsv( $fhandle, array("Directory, Last Modified") );
foreach( $dir_list as $file => $mod_time ) {
	fputcsv($fhandle, array($file,date("Y M d @ g:i:s A",$mod_time)) );
}
fclose( $fhandle );

$fhandle = fopen( $csvFile_files, 'w+' );
fputcsv( $fhandle, array("File, Last Modified") );
foreach( $file_list as $file => $mod_time ) {
	fputcsv($fhandle, array($file,date("Y M d @ g:i:s A",$mod_time)) );
}
fclose( $fhandle );


function dir_parse( $dir, &$d, &$f ) {
	global $timer;
	$handle = opendir($dir);
	while( FALSE !== ($file = readdir($handle)) ):
		if( $file != "." && $file != ".." )
			if( is_dir($dir."\\".$file) ):							# File is a directory
				if( filemtime($dir."\\".$file) < $timer ):			# Directory is old
					$d[$dir."\\".$file] = filemtime($dir."\\".$file);
				else:												# Directory is not old; parse next level
					dir_parse( $dir."\\".$file, $d, $f );
				endif;
			else:													# File is not a directory
				if( filemtime($dir."\\".$file) < $timer )			# File is old
					$f[$dir."\\".$file] = filemtime($dir."\\".$file);
			endif;
	endwhile;
	closedir($handle);
}
	
?>