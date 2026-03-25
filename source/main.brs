sub Main(args as Dynamic)
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)

    scene = screen.CreateScene("MainScene")
    screen.show()

    scene.observeField("openBrowser", m.port)

    while true
        msg = wait(0, m.port)
        msgType = type(msg)

        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return

        else if msgType = "roSGNodeEvent"
            if msg.getField() = "openBrowser"
                url = msg.getData()
                if url <> "" and url <> invalid
                    showBrowser(scene, url)
                end if
            end if
        end if
    end while
end sub

sub showBrowser(scene as Object, url as String)
    port = CreateObject("roMessagePort")

    ' roHtmlWidget requires roRectangle as the first argument (not an AA)
    rect = CreateObject("roRectangle", 0, 0, 1280, 720)
    cfg  = {url: url, messagePort: port, hasKeyboard: false}

    browser = CreateObject("roHtmlWidget", rect, cfg)

    if browser = invalid
        ' roHtmlWidget not available on this firmware
        scene.browserDone = true
        return
    end if

    ' HTTPS certificate support so pages actually load
    browser.SetCertificatesFile("common:/certs/ca-bundle.crt")
    browser.InitClientCertificates()
    browser.show()

    while true
        msg = wait(0, port)
        if type(msg) = "roHtmlWidgetEvent"
            reason = msg.GetData().reason
            if reason = "EXIT_REQUESTED" or reason = "DONE" or reason = "error"
                exit while
            end if
        end if
    end while

    browser = invalid
    scene.browserDone = true
end sub
