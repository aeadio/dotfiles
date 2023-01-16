local binds = {
  { '/', 'cmd',       launch = 'Alacritty' },
  { '/', 'cmd shift', launch = 'Alacritty', args = '-t Floatty' },
  { ',', 'cmd',       cmd    = 'code -n' },
  { ';', 'cmd',       open   = '"$HOME"' },
  { ';', 'cmd shift', launch = 'Alacritty', args = '-t Floatty --working-directory "$HOME" -e ranger' },
--{ "'", 'cmd',       cmd    = '"/Applications/Firefox Developer Edition.app/Contents/MacOS/firefox" -new-window' },
--{ "'", 'cmd shift', cmd    = '"/Applications/Firefox Developer Edition.app/Contents/MacOS/firefox" -private-window' },
  { "'", 'cmd',       launch = 'Vivaldi' },
  { "'", 'cmd shift', launch = 'Vivaldi', args = '--incognito' },
  { '.', 'cmd',       launch = 'Alacritty', args = '-t Floatty -e clac' },
}

local shell = os.getenv('SHELL')
if not shell or shell == '' then
  shell = '/bin/sh'
end

for _, b in ipairs(binds) do
  local cmd
  if b.launch then
    cmd = ('/usr/bin/open -gna "%s" --args %s'):format(b.launch, b.args or '')
  elseif b.open then
    cmd = ('/usr/bin/open "%s"'):format(b.open)
  elseif b.cmd then
    cmd = b.cmd
  end
  -- NOTE: with_user_env to hs.execute() executes in an _interactive_ shell, 
  -- which can be quite slow to start up, but without does not respect the
  -- user's login shell, which may not bootstrap the environment as expected.
  cmd = ("'%s' -c 'SHLVL= exec %s'"):format(shell, cmd:gsub([[']], [['"'"']]))
  hs.hotkey.bind(b[2] or '', b[1], function() hs.execute(cmd) end)
end
