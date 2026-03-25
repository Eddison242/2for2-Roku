function getPlaylists() as Object
    return [
        {name: "North America IPTV", url: "https://iptv-org.github.io/iptv/regions/noram.m3u"},
        {name: "World IPTV",         url: "https://iptv-org.github.io/iptv/index.m3u"},
        {name: "MoveOnJoy",         url: " <------> "},
        {name: "Samsung Tv",         url: " <------> "},
        {name: "Pluto Tv",         url: " <------> "}
     ]
end function

function getBrowserShortcuts() as Object
    return [
        {name: "YouTube",       url: "https://m.youtube.com"},
        {name: "Google Search", url: "https://www.google.com/webhp?igu=1"},
        {name: "Twitch",        url: "https://m.twitch.tv"},
        {name: "Reddit",        url: "https://old.reddit.com"},
        {name: "Wikipedia",     url: "https://www.wikipedia.org"},
        {name: "Weather",       url: "https://wttr.in/?theme=dark"},
        {name: "IMDb",          url: "https://m.imdb.com"},
        {name: "Bing",          url: "https://www.bing.com"},
        {name: "Enter URL...",  url: "_keyboard_"}
    ]
end function

sub init()
    m.playlists      = getPlaylists()
    m.shortcuts      = getBrowserShortcuts()
    m.channelData    = []
    m.activePlaylist = -1
    m.inPlayer       = false
    m.mode           = "iptv"
    m.browserOpen    = false
    m.browserDoneHandled = false

    m.sideList      = m.top.findNode("sideList")
    m.channelList   = m.top.findNode("channelList")
    m.statusLabel   = m.top.findNode("statusLabel")
    m.headerSub     = m.top.findNode("headerSub")
    m.areaLabel     = m.top.findNode("areaLabel")
    m.videoPlayer   = m.top.findNode("videoPlayer")
    m.npLabel       = m.top.findNode("npLabel")
    m.npBg          = m.top.findNode("npBg")
    m.browserList   = m.top.findNode("browserList")
    m.browserHint   = m.top.findNode("browserHint")
    m.tabIPTV       = m.top.findNode("tabIPTV")
    m.tabIPTVLbl    = m.top.findNode("tabIPTVLbl")
    m.tabBrowser    = m.top.findNode("tabBrowser")
    m.tabBrowserLbl = m.top.findNode("tabBrowserLbl")

    m.sideList.observeField("itemSelected",    "onSideSelected")
    m.channelList.observeField("itemSelected", "onChannelSelected")
    m.browserList.observeField("itemSelected", "onBrowserShortcutSelected")
    m.videoPlayer.observeField("state",        "onVideoState")
    m.top.observeField("browserDone",          "onBrowserDone")

    populateSidebar()
    populateBrowserList()
end sub

sub populateSidebar()
    content = CreateObject("roSGNode", "ContentNode")

    browserItem = CreateObject("roSGNode", "ContentNode")
    browserItem.title = "Web Browser"
    content.AppendChild(browserItem)

    for each pl in m.playlists
        item = CreateObject("roSGNode", "ContentNode")
        item.title = pl.name
        content.AppendChild(item)
    end for

    m.sideList.content = content
    m.sideList.visible = true
    m.statusLabel.text = "Choose a playlist or Web Browser"
    m.top.setFocus(true)
    m.sideList.setFocus(true)
end sub

sub populateBrowserList()
    content = CreateObject("roSGNode", "ContentNode")
    for each s in m.shortcuts
        item = CreateObject("roSGNode", "ContentNode")
        item.title = s.name
        content.AppendChild(item)
    end for
    m.browserList.content = content
end sub

sub onSideSelected()
    idx = m.sideList.itemSelected
    if idx < 0 then return

    if idx = 0
        switchMode("browser")
    else
        switchMode("iptv")
        loadPlaylist(idx - 1)
    end if
end sub

sub switchMode(newMode as String)
    m.mode = newMode
    if newMode = "browser"
        m.channelList.visible = false
        m.statusLabel.text    = ""
        m.browserList.visible = true
        m.browserHint.visible = true
        m.areaLabel.text      = "Web Browser"
        m.headerSub.text      = "Select a site or enter a URL"
        m.tabBrowser.color    = "#A020F040"
        m.tabBrowserLbl.color = "#FFFFFFFF"
        m.tabIPTV.color       = "#00000000"
        m.tabIPTVLbl.color    = "#FFFFFF55"
        m.browserList.setFocus(true)
    else
        m.browserList.visible = false
        m.browserHint.visible = false
        m.tabIPTV.color       = "#A020F040"
        m.tabIPTVLbl.color    = "#FFFFFFFF"
        m.tabBrowser.color    = "#00000000"
        m.tabBrowserLbl.color = "#FFFFFF55"
    end if
end sub

sub onBrowserShortcutSelected()
    idx = m.browserList.itemSelected
    if idx < 0 or idx >= m.shortcuts.Count() then return

    s = m.shortcuts[idx]
    if s.url = "_keyboard_"
        showUrlKeyboard()
    else
        openBrowserUrl(s.url)
    end if
end sub

sub openBrowserUrl(url as String)
    if url = "" or url = invalid then return
    m.browserOpen = true
    m.statusLabel.text = "Opening browser..."
    m.top.openBrowser = url
end sub

sub onBrowserDone()
    if not m.top.browserDone then return
    m.browserOpen = false
    m.statusLabel.text = ""
    if m.mode = "browser"
        m.browserList.setFocus(true)
    end if
    m.top.browserDone = false
end sub

sub showUrlKeyboard()
    dialog = CreateObject("roSGNode", "KeyboardDialog")
    dialog.title   = "Web Browser"
    dialog.message = "Type a URL or search term, then select GO"

    ' Explicitly add GO and Cancel buttons so they are visible on screen
    btnList = CreateObject("roArray", 2, false)
    btnList.Push("GO")
    btnList.Push("Cancel")
    dialog.buttons = btnList

    m.top.dialog = dialog
    dialog.observeField("buttonSelected", "onKeyboardButton")
end sub

sub onKeyboardButton()
    dialog = m.top.dialog
    if dialog = invalid then return

    btn = dialog.buttonSelected

    kb = dialog.keyboard
    if kb = invalid
        m.top.dialog = invalid
        return
    end if

    text = kb.text.Trim()
    m.top.dialog = invalid

    ' btn = 0 means GO, anything else means Cancel
    if btn <> 0 then return
    if text = "" then return

    ' Build a proper URL from whatever the user typed
    if text.InStr("://") > 0
        ' Already has a scheme
    else if text.InStr(".") > 0
        text = "https://" + text
    else
        text = "https://www.google.com/search?q=" + text
    end if

    openBrowserUrl(text)
end sub

sub loadPlaylist(idx as Integer)
    if idx < 0 or idx >= m.playlists.Count() then return
    if idx = m.activePlaylist
        if m.channelData.Count() > 0
            m.channelList.setFocus(true)
        end if
        return
    end if

    m.activePlaylist  = idx
    pl = m.playlists[idx]

    m.channelList.visible = false
    m.areaLabel.text      = pl.name
    m.statusLabel.text    = "Fetching channels..."
    m.headerSub.text      = pl.name

    m.fetchTask = CreateObject("roSGNode", "FetchTask")
    m.fetchTask.url = pl.url
    m.fetchTask.observeField("result", "onFetchDone")
    m.fetchTask.control = "RUN"
end sub

sub onFetchDone()
    raw = m.fetchTask.result
    if raw = "" or raw = invalid
        m.statusLabel.text = "Could not load playlist. Check URL or network."
        return
    end if

    m.channelData = parseM3U(raw)
    m.statusLabel.text = ""

    if m.channelData.Count() = 0
        m.statusLabel.text = "No channels found in this playlist."
        return
    end if

    content = CreateObject("roSGNode", "ContentNode")
    for each ch in m.channelData
        item = CreateObject("roSGNode", "ContentNode")
        item.title = ch.name
        content.AppendChild(item)
    end for

    m.channelList.content = content
    m.channelList.visible = true

    plName  = m.playlists[m.activePlaylist].name
    chCount = m.channelData.Count().ToStr()
    m.headerSub.text = plName + " - " + chCount + " channels"
    m.channelList.setFocus(true)
end sub

sub onChannelSelected()
    idx = m.channelList.itemSelected
    if idx < 0 or idx >= m.channelData.Count() then return
    ch = m.channelData[idx]
    playStream(ch.url, ch.name)
end sub

sub playStream(url as String, title as String)
    content = CreateObject("roSGNode", "ContentNode")
    content.url   = url
    content.title = title

    lurl = LCase(url)
    if lurl.InStr(".m3u8") > 0 or lurl.InStr("/hls/") > 0
        content.streamformat = "hls"
    else if lurl.InStr(".mp4") > 0
        content.streamformat = "mp4"
    else if lurl.InStr(".ts") > 0
        content.streamformat = "ts"
    else
        content.streamformat = "hls"
    end if

    m.videoPlayer.content = content
    m.videoPlayer.visible = true
    m.videoPlayer.setFocus(true)
    m.videoPlayer.control = "play"
    m.inPlayer = true

    m.npLabel.text    = "Now Playing: " + title
    m.npLabel.visible = true
    m.npBg.visible    = true
end sub

sub onVideoState()
    state = m.videoPlayer.state
    if state = "error"
        exitPlayer()
        m.statusLabel.text = "Stream unavailable. Try another channel."
    else if state = "finished" or state = "stopped"
        exitPlayer()
    end if
end sub

sub exitPlayer()
    m.videoPlayer.control  = "stop"
    m.videoPlayer.visible  = false
    m.videoPlayer.content  = invalid
    m.npLabel.visible      = false
    m.npBg.visible         = false
    m.inPlayer             = false
    m.channelList.setFocus(true)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if m.browserOpen then return true

    if m.inPlayer
        if key = "back" or key = "options"
            exitPlayer()
            return true
        end if
    else if m.mode = "browser"
        if key = "back"
            switchMode("iptv")
            m.sideList.setFocus(true)
            return true
        end if
    else
        if key = "back"
            if m.channelList.hasFocus()
                m.sideList.setFocus(true)
                return true
            end if
        end if
    end if

    return false
end function

function parseM3U(content as String) as Object
    channels = []
    clean    = content.Replace(Chr(13), "")
    lines    = clean.Split(Chr(10))
    name = ""
    logo = ""
    grp  = ""

    for each rawLine in lines
        line = rawLine.Trim()

        if line.Left(7) = "#EXTINF"
            name = ""
            logo = ""
            grp  = ""

            commaPos = 0
            i = Len(line)
            while i > 0
                if Mid(line, i, 1) = ","
                    commaPos = i
                    i = 0
                end if
                i = i - 1
            end while
            if commaPos > 0
                name = Mid(line, commaPos + 1).Trim()
            end if

            logo = extractAttr(line, "tvg-logo")
            grp  = extractAttr(line, "group-title")

        else if name <> "" and line.Left(4) = "http"
            channels.Push({name: name, url: line, logo: logo, group: grp})
            name = ""
            logo = ""
            grp  = ""
        end if
    end for

    return channels
end function

function extractAttr(line as String, attr as String) as String
    needle = attr + "="
    idx = line.InStr(needle)
    if idx = 0 then return ""
    rest = Mid(line, idx + Len(needle))
    if rest.Left(1) = Chr(34)
        rest = Mid(rest, 2)
        endIdx = rest.InStr(Chr(34))
        if endIdx > 0 then return rest.Left(endIdx - 1)
    end if
    return ""
end function
