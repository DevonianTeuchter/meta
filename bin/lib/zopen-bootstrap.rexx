/* rexx */
/* START OF SPECIFICATIONS ***********************************************/
/*    NAME            : zopenbootstrap                                */
/*    DESCRIPTIVE NAME: Small utility that downloads base components to  */
/*                      get a system that bootstraps into a full zopen   */
/*                      environment.                                     */
/* END OF SPECIFICATIONS  * * * * * * * * * * * * * * * * * * * * * * ****/
DEBUG = 0
trace o

PROGRAM = 'zopenBootStrap'
VERSION = '0.0.1'
MAINTAINER = 'wilsonrs@uk.ibm.com'
ISSUESTO = 'tbd'
call SYSCALLS 'ON'
tlsCipherSuiteList = 'C02F' || 'C027' || 'C030'
tlsCipherSuiteList = tlsCipherSuiteList || 'C028' || '009C' || '009D' || '003C'

rootfs=environment('ZOPEN_ROOTFS')
bootdir=rootfs"/boot"
cachedir=rootfs"/var/cache/zopen"
url = "https://github.com/ZOSOpenTools/curlport/releases/download/"
url = url||"curlport_420/curl-7.83.1.20230120_231325.zos.pax.Z"
paxname=SUBSTR(url, 1+LASTPOS('/', url))

if stream(cachedir||'/'||paxname, "c", "QUERY EXISTS") /= '' then do
  dbg("Using cached version of package")
end
else do
  tmpdir = "/tmp/zopenbs"
  say "Making temp dir"
  cmd = 'mkdir -p -m 777 '||tmpdir
  cmd
  keydbfile=tmpdir||"/hwt.kdb"
  keydbrdb=tmpdir||"/hwt.rdb"
  keydbstash=tmpdir||"/hwt.sth"
  cmd = "rm "keydbfile" "keydbrdb" "keydbstash
  dbg("cmd:"cmd";bpxwunix:"bpxwunix(cmd, , out.,err.))
  say "Generating HWT kdb..."
      stdin.1='1'
      stdin.2=keydbfile
      stdin.3='zbs'
      stdin.4='zbs'
      stdin.5=''
      stdin.6=''
      stdin.7='0'
      stdin.8=''
      stdin.9='0'
      stdin.0 = 9
  bpxrc=bpxwunix('gskkyman',stdin.,out.,err.)
  dbg("gskkyman:"bpxrc";out.0:"out.0";err:"err.0)
  do i = 1 to out.0
    dbg( "bpxwunix: "out.i)
  end
  say "Generating HWT stash..."
      stdin.1='zbs'
      stdin.0 = 1
  bpxrc=bpxwunix('gskkyman -s -k 'keydbfile,stdin.,out.,err.)
  dbg("gskkyman:"bpxrc";out.0:"out.0";err:"err.0)
  do i = 1 to out.0
    dbg( "bpxwunix:`  "out.i)
  end
  certfile=tmpdir||"/cert.pem"
  parse source os calltype thisfile therest
  certcount = 0
  wtf = 0
  CRLF = "15"x
  
  do while lines(thisfile) > 0
    line_str = linein(thisfile)
    if WORDPOS("-----BEGIN CERTIFICATE-----", line_str) /= 0 then do
      filehandle = stream(certfile,'c','open write replace')
      dbg( "Enabling write to file:" certfile)
      wtf = 1
    end
    if wtf = 1 then do
      call charout filehandle, line_str
      call charout filehandle, CRLF
    end
    if WORDPOS("-----END CERTIFICATE-----", line_str) /= 0 then do
      call stream certfile,c,"close"
      
      wtf = 0
      certcount = certcount + 1
      stdin.1='2'
      stdin.2=keydbfile
      stdin.3='zbs'
      stdin.4='7'
      stdin.5=certfile
      stdin.6='cert-'certcount
      stdin.7=''
      stdin.8='0'
      stdin.0 = 8
      bpxrc=bpxwunix('gskkyman',stdin.,out.,err.)
      dbg( "gskkyman:"bpxrc";out.0:"out.0";err:"err.0)
      do i = 1 to out.0
        dbg( "bpxwunix:out:"out.i)
      end
      do i = 1 to err.0
        dbg( "bpxwunix:err:"err.i)
      end
    end
  end

  parse var url SCHEME '://' HOST '/' URIPATH
  URIAUTH = SCHEME||'://'||HOST
  URIPATH = '/'||URIPATH
  
  /**/
  call hwtcalls 'on'
  call syscalls 'SIGOFF'
  address hwthttp "hwtconst " "ReturnCode " "DiagArea."
  dbg( "RC:"rc";ReturnCode:"ReturnCode)
  /**/  
  ConnectionHandle = ''
  RequestHandle = ''
  ExpectedResponseStatus = 200
  ResponseStatusCode = ''
  ResponseReason = ''
  ResponseHeaders. = ''
  ResponseBody = ''
  ReturnCode = -1
  DiagArea. = ''
  /**/
  HandleType = HWTH_HANDLETYPE_CONNECTION
  ConnectionHandle = ''
  address hwthttp "hwthinit " "ReturnCode " "HandleType " "HandleOut ",
                  "DiagArea."
  dbg("RC:"rc";ReturnCode:"ReturnCode)
  ConnectionHandle = HandleOut
  /**/  
  address hwthttp "hwthset " "ReturnCode " "ConnectionHandle " "HWTH_OPT_URI ",
                  "URIAUTH " "DiagArea."
  dbg("hwthset(HWTH_OPT_URI):"rc";RC:"ReturnCode"(0x"D2X(ReturnCode)")")
  address hwthttp "hwthset " "ReturnCode " "ConnectionHandle ",
                  "HWTH_OPT_COOKIETYPE " "HWTH_COOKIETYPE_SESSION " "DiagArea."
  dbg("hwthset(COOKIETYPE):"rc";RC:"ReturnCode"(0x"D2X(ReturnCode)")")
  address hwthttp "hwthset " "ReturnCode " "ConnectionHandle ",
                  "HWTH_OPT_SNDTIMEOUTVAL " "10 " "DiagArea."
  dbg("hwthset(SNDTIMEOUTVAL):"rc";RC:"ReturnCode"(0x"D2X(ReturnCode)")")
  address hwthttp "hwthset " "ReturnCode " "ConnectionHandle ",
                  "HWTH_OPT_RCVTIMEOUTVAL " "10 " "DiagArea."
  dbg("hwthset(RCVTIMEOUTVAL):"rc";RC:"ReturnCode"(0x"D2X(ReturnCode)")")
  address hwthttp "hwthset " "ReturnCode " "ConnectionHandle ",
                  "HWTH_OPT_USE_SSL " "HWTH_SSL_USE " "DiagArea."
  dbg("hwthset(USE_SSL):"rc";RC:"ReturnCode"(0x"D2X(ReturnCode)")")
  address hwthttp "hwthset " "ReturnCode " "ConnectionHandle ",
                  "HWTH_OPT_SSLVERSION " "HWTH_SSLVERSION_TLSv12 " "DiagArea."
  dbg("hwthset(SSLVERSION):"rc";RC:"ReturnCode"(0x"D2X(ReturnCode)")")
  address hwthttp "hwthset " "ReturnCode " "ConnectionHandle ",
                  "HWTH_OPT_SSLCIPHERSPECS " "tlsCipherSuiteList " "DiagArea."
  dbg("hwthset(SSLCIPHERSPECS):"rc";RC:"ReturnCode"(0x"D2X(ReturnCode)")")
  address hwthttp "hwthset " "ReturnCode " "ConnectionHandle ",
                  "HWTH_OPT_SSLKEYTYPE " "HWTH_SSLKEYTYPE_KEYDBFILE ",
                  "DiagArea."
  dbg("hwthset(SSLKEYTYPE):"rc";RC:"ReturnCode"(0x"D2X(ReturnCode)")")
  address hwthttp "hwthset " "ReturnCode " "ConnectionHandle ",
                  "HWTH_OPT_SSLKEY " "keydbfile " " DiagArea."
  dbg("hwthset(SSLKEY/"keydbfile"):"rc";RC:"ReturnCode"(0x"D2X(ReturnCode)")")
  address hwthttp "hwthset " "ReturnCode " "ConnectionHandle "i,
                  "HWTH_OPT_SSLKEYSTASHFILE " "keydbstash " " DiagArea."
  dbg("hwthset(SSLKEYSTASHFILE):"rc";RC:"ReturnCode"(0x"D2X(ReturnCode)")")
  address hwthttp "hwthset " "ReturnCode " "ConnectionHandle ",
                  "HWTH_OPT_MAX_REDIRECTS " "10 " "DiagArea."
  dbg("hwthset(MAX_REDIRECTS):"rc";RC:"ReturnCode"(0x"D2X(ReturnCode)")")
  address hwthttp "hwthset " "ReturnCode " "ConnectionHandle ",
                  "HWTH_OPT_XDOMAIN_REDIRECTS " "HWTH_XDOMAIN_REDIRS_ALLOWED ",
                  "DiagArea."
  dbg("hwthset(XDOMAIN_REDIRECTS):"rc";RC:"ReturnCode"(0x"D2X(ReturnCode)")")
  /**/
  DiagArea.=''
  address hwthttp "hwthconn " "ReturnCode " "ConnectionHandle " "DiagArea. "
  dbg("hwthconnRC:"rc";ReturnCode:"ReturnCode"(0x"D2X(ReturnCode),
      ");DiagArea:Service:"DiagArea.Service";ReasonCode:"DiagArea.ReasonCode,
      ";ReasonDesc:"DiagArea.ReasonDesc)
  /**/
  RequestHandle = ''
  address hwthttp "hwthinit " "ReturnCode " "HWTH_HANDLETYPE_HTTPREQUEST ",
                  "HandleOut " "DiagArea."
  dbg("hwthinit:"rc";ReturnCode:"ReturnCode"(0x"D2X(ReturnCode),
      ");DiagArea:Service:"DiagArea.Service";ReasonCode:"DiagArea.ReasonCode,
      ";ReasonDesc:"DiagArea.ReasonDesc)
  RequestHandle = HandleOut
  /**/  
  SList=''
  header  = "User-Agent:"PROGRAM"/"VERSION
  SListfn = HWTH_SLST_NEW
  address hwthttp "hwthslst " "ReturnCode " "RequestHandle " "SListfn ",
                  "SList " "header " "DiagArea."
  dbg("hwthslst:"rc";RC:"ReturnCode"(0x"D2X(ReturnCode)");DiagArea:Service:",
      DiagArea.Service";ReasonCode:"DiagArea.ReasonCode";ReasonDesc:",
      DiagArea.ReasonDesc)
  Address hwthttp "hwthset " "ReturnCode " "RequestHandle ",
                  "HWTH_OPT_REQUESTMETHOD " "HWTH_HTTP_REQUEST_GET ",
                  "DiagArea."
  dbg("hwthttp:"rc";RC:"ReturnCode"(0x"D2X(ReturnCode)")")
  address hwthttp "hwthset " "ReturnCode " "RequestHandle ",
                  "HWTH_OPT_HTTPHEADERS " "SList " "DiagArea."
  dbg("hwthslst:"rc";RC:"ReturnCode"(0x"D2X(ReturnCode)")")
  Address hwthttp "hwthset " "ReturnCode " "RequestHandle ",
                   "HWTH_OPT_URI " "URIPATH " "DiagArea."
  dbg("hwthslst:"rc";RC:"ReturnCode"(0x"D2X(ReturnCode)")")
  Address hwthttp "hwthset " "ReturnCode " "RequestHandle ",
                  "HWTH_OPT_TRANSLATE_RESPBODY " "HWTH_XLATE_RESPBODY_NONE ",
                  "DiagArea."
  dbg("hwthslst:"rc";RC:"ReturnCode"(0x"D2X(ReturnCode)")")
  address hwthttp "hwthset " "ReturnCode " "RequestHandle ",
                  "HWTH_OPT_RESPONSEHDR_USERDATA " "ResponseHeaders. ",
                  "DiagArea."
  dbg("hwthslst:"rc";RC:"ReturnCode"(0x"D2X(ReturnCode)")")
  address hwthttp "hwthset " "ReturnCode " "RequestHandle ",
                  "HWTH_OPT_RESPONSEBODY_USERDATA" "ResponseBody " "DiagArea."
  dbg("hwthslst:"rc";RC:"ReturnCode"(0x"D2X(ReturnCode)")")
  /**/  
  address hwthttp "hwthrqst " "ReturnCode " "ConnectionHandle ",
                  "RequestHandle " "HttpStatusCode " "HttpReasonCode "i,
                  "DiagArea."
  dbg("RC:"rc";ReturnCode:"ReturnCode)
  /**/  
  forceOption = HWTH_NOFORCE
  address hwthttp "hwthterm " "ReturnCode " "RequestHandle " "forceOption ",
                  "DiagArea."
  dbg("RC:"rc";ReturnCode:"ReturnCode"(0x"D2X(ReturnCode)")")
  address hwthttp "hwthdisc " "ReturnCode " "ConnectionHandle " "DiagArea."
  dbg("RC:"rc";ReturnCode:"ReturnCode"(0x"D2X(ReturnCode)")")
  forceOption = HWTH_NOFORCE
  address hwthttp "hwthterm "  "ReturnCode "  "ConnectionHandle ",
                  "forceOption " "DiagArea."
  dbg("RC:"rc";ReturnCode:"ReturnCode"(0x"D2X(ReturnCode)")")
  filehandle = stream((cachedir||"/"||paxname),'c','open write replace')
  call charout filehandle, ResponseBody
  call stream filehandle,c,"close"
end
say "Expanding curl..."
cmd = "pax -r"
if DEBUG = 1 then
  cmd = cmd||"v"
cmd = cmd||"f "cachedir||"/"||paxname||" -s##"||bootdir||"/#"
cmd
exit

dbg:
parse arg outparams
if DEBUG = 1 then
  say outparams
return ''

/*****************************************************/
/* Github Public Certs for HWT to connect over HTTPS */
-----BEGIN CERTIFICATE-----
MIIDrzCCApegAwIBAgIQCDvgVpBCRrGhdWrJWZHHSjANBgkqhkiG9w0BAQUFADBh
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD
QTAeFw0wNjExMTAwMDAwMDBaFw0zMTExMTAwMDAwMDBaMGExCzAJBgNVBAYTAlVT
MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
b20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IENBMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4jvhEXLeqKTTo1eqUKKPC3eQyaKl7hLOllsB
CSDMAZOnTjC3U/dDxGkAV53ijSLdhwZAAIEJzs4bg7/fzTtxRuLWZscFs3YnFo97
nh6Vfe63SKMI2tavegw5BmV/Sl0fvBf4q77uKNd0f3p4mVmFaG5cIzJLv07A6Fpt
43C/dxC//AH2hdmoRBBYMql1GNXRor5H4idq9Joz+EkIYIvUX7Q6hL+hqkpMfT7P
T19sdl6gSzeRntwi5m3OFBqOasv+zbMUZBfHWymeMr/y7vrTC0LUq7dBMtoM1O/4
gdW7jVg/tRvoSSiicNoxBN33shbyTApOB6jtSj1etX+jkMOvJwIDAQABo2MwYTAO
BgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUA95QNVbR
TLtm8KPiGxvDl7I90VUwHwYDVR0jBBgwFoAUA95QNVbRTLtm8KPiGxvDl7I90VUw
DQYJKoZIhvcNAQEFBQADggEBAMucN6pIExIK+t1EnE9SsPTfrgT1eXkIoyQY/Esr
hMAtudXH/vTBH1jLuG2cenTnmCmrEbXjcKChzUyImZOMkXDiqw8cvpOp/2PV5Adg
06O/nVsJ8dWO41P0jmP6P6fbtGbfYmbW0W5BjfIttep3Sp+dWOIrWcBAI+0tKIJF
PnlUkiaY4IBIqDfv8NZ5YBberOgOzW6sRBc4L0na4UU+Krk2U886UAb3LujEV0ls
YSEY1QSteDwsOoBrp+uvFRTp2InBuThs4pFsiv9kuXclVzDAGySj4dzp30d8tbQk
CAUw7C29C79Fv1C5qfPrmAESrciIxpg0X40KPMbp1ZWVbd4=
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIEFzCCAv+gAwIBAgIQB/LzXIeod6967+lHmTUlvTANBgkqhkiG9w0BAQwFADBh
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD
QTAeFw0yMTA0MTQwMDAwMDBaFw0zMTA0MTMyMzU5NTlaMFYxCzAJBgNVBAYTAlVT
MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxMDAuBgNVBAMTJ0RpZ2lDZXJ0IFRMUyBI
eWJyaWQgRUNDIFNIQTM4NCAyMDIwIENBMTB2MBAGByqGSM49AgEGBSuBBAAiA2IA
BMEbxppbmNmkKaDp1AS12+umsmxVwP/tmMZJLwYnUcu/cMEFesOxnYeJuq20ExfJ
qLSDyLiQ0cx0NTY8g3KwtdD3ImnI8YDEe0CPz2iHJlw5ifFNkU3aiYvkA8ND5b8v
c6OCAYIwggF+MBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFAq8CCkXjKU5
bXoOzjPHLrPt+8N6MB8GA1UdIwQYMBaAFAPeUDVW0Uy7ZvCj4hsbw5eyPdFVMA4G
A1UdDwEB/wQEAwIBhjAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwdgYI
KwYBBQUHAQEEajBoMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5j
b20wQAYIKwYBBQUHMAKGNGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdp
Q2VydEdsb2JhbFJvb3RDQS5jcnQwQgYDVR0fBDswOTA3oDWgM4YxaHR0cDovL2Ny
bDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0R2xvYmFsUm9vdENBLmNybDA9BgNVHSAE
NjA0MAsGCWCGSAGG/WwCATAHBgVngQwBATAIBgZngQwBAgEwCAYGZ4EMAQICMAgG
BmeBDAECAzANBgkqhkiG9w0BAQwFAAOCAQEAR1mBf9QbH7Bx9phdGLqYR5iwfnYr
6v8ai6wms0KNMeZK6BnQ79oU59cUkqGS8qcuLa/7Hfb7U7CKP/zYFgrpsC62pQsY
kDUmotr2qLcy/JUjS8ZFucTP5Hzu5sn4kL1y45nDHQsFfGqXbbKrAjbYwrwsAZI/
BKOLdRHHuSm8EdCGupK8JvllyDfNJvaGEwwEqonleLHBTnm8dqMLUeTF0J5q/hos
Vq4GNiejcxwIfZMy0MJEGdqN9A57HSgDKwmKdsp33Id6rHtSJlWncg+d0ohP/rEh
xRqhqjn1VtvChMQ1H3Dau0bwhr9kAMQ+959GG50jBbl9s08PqUU643QwmA==
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIFajCCBPCgAwIBAgIQBRiaVOvox+kD4KsNklVF3jAKBggqhkjOPQQDAzBWMQsw
CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMTAwLgYDVQQDEydEaWdp
Q2VydCBUTFMgSHlicmlkIEVDQyBTSEEzODQgMjAyMCBDQTEwHhcNMjIwMzE1MDAw
MDAwWhcNMjMwMzE1MjM1OTU5WjBmMQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2Fs
aWZvcm5pYTEWMBQGA1UEBxMNU2FuIEZyYW5jaXNjbzEVMBMGA1UEChMMR2l0SHVi
LCBJbmMuMRMwEQYDVQQDEwpnaXRodWIuY29tMFkwEwYHKoZIzj0CAQYIKoZIzj0D
AQcDQgAESrCTcYUh7GI/y3TARsjnANwnSjJLitVRgwgRI1JlxZ1kdZQQn5ltP3v7
KTtYuDdUeEu3PRx3fpDdu2cjMlyA0aOCA44wggOKMB8GA1UdIwQYMBaAFAq8CCkX
jKU5bXoOzjPHLrPt+8N6MB0GA1UdDgQWBBR4qnLGcWloFLVZsZ6LbitAh0I7HjAl
BgNVHREEHjAcggpnaXRodWIuY29tgg53d3cuZ2l0aHViLmNvbTAOBgNVHQ8BAf8E
BAMCB4AwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMIGbBgNVHR8EgZMw
gZAwRqBEoEKGQGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRMU0h5
YnJpZEVDQ1NIQTM4NDIwMjBDQTEtMS5jcmwwRqBEoEKGQGh0dHA6Ly9jcmw0LmRp
Z2ljZXJ0LmNvbS9EaWdpQ2VydFRMU0h5YnJpZEVDQ1NIQTM4NDIwMjBDQTEtMS5j
cmwwPgYDVR0gBDcwNTAzBgZngQwBAgIwKTAnBggrBgEFBQcCARYbaHR0cDovL3d3
dy5kaWdpY2VydC5jb20vQ1BTMIGFBggrBgEFBQcBAQR5MHcwJAYIKwYBBQUHMAGG
GGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBPBggrBgEFBQcwAoZDaHR0cDovL2Nh
Y2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VExTSHlicmlkRUNDU0hBMzg0MjAy
MENBMS0xLmNydDAJBgNVHRMEAjAAMIIBfwYKKwYBBAHWeQIEAgSCAW8EggFrAWkA
dgCt9776fP8QyIudPZwePhhqtGcpXc+xDCTKhYY069yCigAAAX+Oi8SRAAAEAwBH
MEUCIAR9cNnvYkZeKs9JElpeXwztYB2yLhtc8bB0rY2ke98nAiEAjiML8HZ7aeVE
P/DkUltwIS4c73VVrG9JguoRrII7gWMAdwA1zxkbv7FsV78PrUxtQsu7ticgJlHq
P+Eq76gDwzvWTAAAAX+Oi8R7AAAEAwBIMEYCIQDNckqvBhup7GpANMf0WPueytL8
u/PBaIAObzNZeNMpOgIhAMjfEtE6AJ2fTjYCFh/BNVKk1mkTwBTavJlGmWomQyaB
AHYAs3N3B+GEUPhjhtYFqdwRCUp5LbFnDAuH3PADDnk2pZoAAAF/jovErAAABAMA
RzBFAiEA9Uj5Ed/XjQpj/MxQRQjzG0UFQLmgWlc73nnt3CJ7vskCICqHfBKlDz7R
EHdV5Vk8bLMBW1Q6S7Ga2SbFuoVXs6zFMAoGCCqGSM49BAMDA2gAMGUCMCiVhqft
7L/stBmv1XqSRNfE/jG/AqKIbmjGTocNbuQ7kt1Cs7kRg+b3b3C9Ipu5FQIxAM7c
tGKrYDGt0pH8iF6rzbp9Q4HQXMZXkNxg+brjWxnaOVGTDNwNH7048+s/hT9bUQ==
-----END CERTIFICATE-----


