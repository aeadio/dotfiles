local binds = {
  { '/', 'cmd',       launch = 'Alacritty' },
  { '/', 'cmd shift', launch = 'Alacritty', args = '-t Floatty' },
  { ',', 'cmd',       cmd    = 'code -n' },
  { ';', 'cmd',       open   = '"$HOME"' },
  { ';', 'cmd shift', launch = 'Alacritty', args = '-t Floatty --working-directory "$HOME" -e ranger' },
  { "'", 'cmd',       launch = 'Firefox Developer Edition' },
  { "'", 'cmd shift', launch = 'Firefox Developer Edition', args = '-private-window' },
  { '.', 'cmd',       launch = 'Alacritty', args = '-t Floatty -e clac' },
}

local shell = os.getenv('SHELL')
for _, b in ipairs(binds) do
  local cmd
  if b.launch then
    cmd = ('/usr/bin/open -gna "%s" --args %s'):format(b.launch, b.args or '')
  elseif b.open then
    cmd = ('/usr/bin/open -gn "%s"'):format(b.open)
  elseif b.cmd then
    cmd = b.cmd
  end
  -- NOTE: with_user_env to hs.execute() executes in an _interactive_ shell, 
  -- which can be quite slow to start up, but without does not respect the
  -- user's login shell, which may not bootstrap the environment as expected.
  -- XXX: single quotes are not correctly escaped
  cmd = ("'%s' -c 'SHLVL= exec %s'"):format(shell, cmd)
  hs.hotkey.bind(b[2] or '', b[1], function() hs.execute(cmd) end)
end
