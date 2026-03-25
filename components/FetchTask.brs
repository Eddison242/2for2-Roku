sub init()
    m.top.functionName = "doFetch"
end sub

sub doFetch()
    http = CreateObject("roUrlTransfer")
    http.SetUrl(m.top.url)
    http.SetCertificatesFile("common:/certs/ca-bundle.crt")
    http.InitClientCertificates()
    m.top.result = http.GetToString()
end sub
