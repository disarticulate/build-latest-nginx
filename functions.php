<?php

function latest(){
/*
*  
*       get current available nginx version 
* 
*/
    $n = [];
    exec("curl -s http://nginx.org/download/|grep \"tar.gz<\"|grep nginx|sed 's/.*href=\"//'|sed 's/\".*//'|grep '^[a-zA-Z].*'", $out);
    foreach ($out as $k => $v) {
        $t = str_replace(['.tar.gz', 'nginx-'], '', $v);
        list($major, $minor, $patch) = explode('.', $t);
        $n[sprintf('%02s', $major) . sprintf('%02s', $minor) . sprintf('%02s', $patch)] = ['version' => $t, 'file' => $v];
    }
    ksort($n);
    $lv=end($n);
    if(empty($lv)){
        die('failed to get the latest version from nginx.org');
    }
    return $lv;
}




function cfg($key,$value,$onoff,$infile){
    /*
    *   basic  config file manipulation; 
    *   usage:
    *   key value       // cfg("INPUT",' 12,'enable',$file);
    *   key= value -    //cfg("INPUT=",'"some text in quotes"','enable',$file);    
    */
    $data=file($infile); 
    $newdata="";
    $match=false;
    foreach($data as $line){   
        if(preg_match("/^#?\s?+{$key}(\s|=?)/",$line)){
            $match=true;            
            if($onoff==true ||$onoff=="enable"||$onoff=="on"){
                $line="$key $value";
                echo "enable: {$line}  ";
            }else{
                $line="# $key $value";
                echo "disable: {$line}  ";
            }
            $line.=PHP_EOL;    
            echo PHP_EOL;
        }
        $newdata.=$line;
    }
    if(!$match){
        $newdata.="$key $value".PHP_EOL;
    }
    file_put_contents($infile,$newdata);
}

function ask($q, $yn = false, $abort = true){
    echo $q . PHP_EOL;
    $handle = fopen("php://stdin", "r");
    $line = fgets($handle);
    fclose($handle);
    $line = preg_replace('~[[:cntrl:]]~', '', $line);
    if ($yn) {
        if(empty($line)){
            return true;
        }
        if (substr(strtolower(trim($line)), 0, 1) !== 'y') {
            if ($abort) {
                echo "Script aborted!", PHP_EOL;
                die();
            } else {
                return false;
            }
        } else {
            return true;
        }
    }
    return $line;
}



?>