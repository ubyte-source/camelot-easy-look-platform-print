<?php

namespace applications\cli\actions;

set_time_limit(300);

use configurations\IAM;

use IAM\Sso;
use IAM\Request as IAMRequest;
use IAM\Gateway;
use IAM\Configuration as IAMConfiguration;

use Knight\armor\Output;
use Knight\armor\Request;
use Knight\armor\Navigator;

const IMPERSONATE = 'iam/user/impersonate';
const PRINTX = 'api/document/output/print';
const CHROME = 'chromium-browser --disable-web-security --headless --no-sandbox --ignore-certificate-errors --all-renders --disable-gpu --use-gl=swiftshader --disable-extension --disable-dev-shm-usage --incognito --print-to-pdf-no-header --run-all-compositor-stages-before-draw --enable-cloud-print-proxy --use-vulkan --no-first-run --disable-audio-output --disable-touch-adjustment --disable-touch-drag-drop --disable-notifications --disable-sync --disable-back-forward-cache --disable-component-update --virtual-time-budget=%d --disk-cache-dir=%s --user-agent=%s --print-to-pdf=%s %s';
const RENDERING = '/app/rendering.sh -i %s';
const CHROME_VIRTUAL = 6e5;
const SLEEP = 2e6;

function name(string $title) : string
{
    $replace = array_map('chr', range(0, 32));
    $replace = array_merge($replace, [chr(60), chr(62), chr(58), chr(34), chr(47), chr(92), chr(124), chr(43), chr(37), chr(63), chr(42)]);
    $constra = urlencode($title);
    $constra = str_replace($replace, chr(95), $constra);
    $constra = preg_replace('/' . chr(95) . '+/', chr(95), $constra);
    return trim($constra, chr(95));
}

$parameters = parse_url($_SERVER[Navigator::REQUEST_URI], PHP_URL_PATH);
$parameters = explode(chr(47), $parameters);
$parameters = array_filter($parameters, 'strlen');
$parameters = array_values($parameters);
$parameters = array_slice($uri, 1 + Navigator::getDepth());

$client = Navigator::getClientIP(Navigator::HTTP_X_OVERRIDE_IP_ENABLE);
$client = long2ip($client);
if (!!filter_var($client, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4 | FILTER_FLAG_NO_PRIV_RANGE)) {
    $application_basename = IAMConfiguration::getApplicationBasename();
    if (Sso::youHaveNoPolicies($application_basename . '/cli/action/pdf')) Output::print(false);
    array_unshift($parameters, Sso::getWhoamiKey());
}

IAMRequest::instance(null, IAM::USERNAME, IAM::PASSWORD);
$impersonate_user = array_shift($parameters);
$impersonate_user = IMPERSONATE . chr(47) . (string)$impersonate_user;
$impersonate = Gateway::callAPI('iam', $impersonate_user);

$parameters = implode(chr(47), $parameters);

$output = Gateway::getLink('pdf');
$report = $output . PRINTX . chr(47) . $parameters . chr(63) . 'timestamp' . chr(61) . time();
$report_get = Request::get();
if (null !== $report_get) $report = $report . chr(38) . http_build_query((array)$report_get);

$report = base64_encode($report);
$output = $output . 'api' . chr(47) . Sso::AUTHORIZATION . chr(47) . $impersonate->authorization . chr(63) . Navigator::RETURN_URL . chr(61) . $report;

$exec_command_xarguments = array();
$path_tempdir = sys_get_temp_dir();
$path = tempnam($path_tempdir, 'pdf');
array_push($exec_command_xarguments, $path_tempdir);
array_push($exec_command_xarguments, Navigator::getUserAgent());
array_push($exec_command_xarguments, $path);
array_push($exec_command_xarguments, $output);
$exec_command_xarguments = preg_filter('/^.*$/', chr(34) . '$0' . chr(34), $exec_command_xarguments);
array_unshift($exec_command_xarguments, CHROME, CHROME_VIRTUAL);
$exec_command = call_user_func_array('sprintf', $exec_command_xarguments);

do {
    exec($exec_command);
    $size = filesize($path);
    clearstatcache();
    usleep(SLEEP);
} while ((int)$size < 1024);

$exec_command_rendering = sprintf(RENDERING, $path);
exec($exec_command_rendering);

usleep(SLEEP);

header('Content-type: application/pdf');
header('Content-Length: ' . filesize($path));
$report_get_filename = Request::get('filename');
if (null !== $report_get_filename)
    header('Content-Disposition: inline; filename=' . chr(34) . name($report_get_filename) . chr(46) . 'pdf' . chr(34));

$file = @fopen($path, 'r');
if ($file) {
    while (($buffer = fgets($file, 1024)) !== false) echo $buffer;
    fclose($file);
}
@unlink($path);

exit;
