sub init()
  m.top.backgroundURI = "pkg:/images/background-controls.jpg"

  m.selectedItemURL = ""

  m.save_feed_url = m.top.FindNode("save_feed_url") 'Save url to registry

  m.get_channel_list = m.top.FindNode("get_channel_list") 'get url from registry and parse the feed
  m.get_channel_list.ObserveField("content", "SetContent") 'Is thre content parsed? If so, goto SetContent sub and dsipay list

  m.list = m.top.FindNode("list")
  m.list.ObserveField("itemSelected", "setChannel")

  m.video = m.top.FindNode("Video")
  m.video.ObserveField("state", "checkState")

  showdialog() 'Force a keyboard dialog.
  
  m.save_feed_url.control = "stop"
  m.top.dialog.close = true
  m.get_channel_list.control = "RUN"
end sub

' **************************************************************

sub minimizePlayer()
  m.list.SetFocus(true)
  m.video.translation = [800, 100]
  m.video.width = 960
  m.video.height = 540
end sub

sub maximizePlayer()
  m.list.SetFocus(false)
  m.top.SetFocus(true)
  m.video.translation = [0, 0]
  m.video.width = 0
  m.video.height = 0
end sub

sub togglePlayerFullscreen()
  if m.video.width = 0 ' if player is in fullscreen mode
    minimizePlayer()
  else
    maximizePlayer()
  end if
end sub

sub togglePlayerPlayPause()
  if m.video.control = "play"
    m.video.control = "pause"
  else
    m.video.control = "play"
  end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  result = false

  if press
    if key = "play"
      togglePlayerPlayPause()
      result = true
    else if key = "OK" and m.video.content.url = m.selectedItemURL
      togglePlayerFullscreen()
    else if key = "right"
      maximizePlayer()
      result = true
    else if key = "left"
      minimizePlayer()
      result = true
    else if key = "back"
      if m.video.width = 0
        minimizePlayer()
      else 
        if m.video.state = "playing"
          m.video.control = "pause"
        ' else ' if video is already stopped then exit the app
        '   end
        end if
      end if
      result = true
    else if(key = "options")
      showdialog()
      result = true
    end if
  end if

  return result
end function


sub checkState()
  state = m.video.state
  if(state = "error")
    m.top.dialog = CreateObject("roSGNode", "Dialog")
    m.top.dialog.title = "Error: " + str(m.video.errorCode)
    m.top.dialog.message = m.video.errorMsg
  end if
end sub

sub SetContent()
  m.list.content = m.get_channel_list.content
  m.list.SetFocus(true)
end sub

sub setChannel()
  if m.list.content.getChild(0).getChild(0) = invalid
    content = m.list.content.getChild(m.list.itemSelected)
  else
    itemSelected = m.list.itemSelected
    for i = 0 to m.list.currFocusSection - 1
      itemSelected = itemSelected - m.list.content.getChild(i).getChildCount()
    end for
    content = m.list.content.getChild(m.list.currFocusSection).getChild(itemSelected)
  end if

  'Probably would be good to make content = content.clone(true) but for now it works like this
  content.streamFormat = "hls,mp4,mkv,mp3,dash,wpa,etc."

  if m.video.content <> invalid and m.video.content.url = content.url
    m.selectedItemURL = content.url
    return
  end if

  content.HttpSendClientCertificates = true
  content.HttpCertificatesFile = "common:/certs/ca-bundle.crt"
  m.video.EnableCookies()
  m.video.SetCertificatesFile("common:/certs/ca-bundle.crt")
  m.video.InitClientCertificates()

  m.video.content = content

  m.top.backgroundURI = "pkg:/images/rsgde_bg_hd.jpg"
  m.video.trickplaybarvisibilityauto = false

  m.video.control = "play"
end sub


sub showdialog()
  print ">>>  ENTERING KEYBOARD <<<"
  keyboarddialog = createObject("roSGNode", "KeyboardDialog")
  keyboarddialog.backgroundUri = "pkg:/images/rsgde_bg_hd.jpg"
  keyboarddialog.title = "Enter .m3u URL"

  keyboarddialog.buttons = ["OK", "Set back to Demo", "Save"]
  keyboarddialog.optionsDialog = true

  m.top.dialog = keyboarddialog
  m.top.dialog.text = m.global.feedurl
  m.top.dialog.keyboard.textEditBox.cursorPosition = len(m.global.feedurl)
  m.top.dialog.keyboard.textEditBox.maxTextLength = 300

  KeyboardDialog.observeFieldScoped("buttonSelected", "onKeyPress") 'we observe button ok/cancel, if so goto to onKeyPress sub
end sub


sub onKeyPress()
  if m.top.dialog.buttonSelected = 0 ' OK
    url = m.top.dialog.text
    m.global.feedurl = url
    m.save_feed_url.control = "RUN"
    m.top.dialog.close = true
    m.get_channel_list.control = "RUN"
  else if m.top.dialog.buttonSelected = 1 ' Set back to Demo
    m.top.dialog.text = "https://mater.com.ua/ip/ua.m3u"
  else if m.top.dialog.buttonSelected = 2 ' Save
    m.global.feedurl = m.top.dialog.text
    m.save_feed_url.control = "RUN"
    '    m.top.dialog.visible ="false"
    '    m.top.unobserveField("buttonSelected")
  end if
end sub
