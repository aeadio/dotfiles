local hyper = 'cmd ctrl alt shift'

local binds = {  
  -- General applications
  { 'z',  hyper, launch = 'Vivaldi' },
  { 'x',  hyper, launch = 'Vivaldi', args = '--incognito' },
  { 'e',  hyper, cmd    = 'code -n' },
  
  -- Utilities
  { '/',  hyper, launch = 'Alacritty' },
  { 'v',  hyper, launch = 'Alacritty', args = '-e clac' },
  { 'h', hyper, open   = '"$HOME"' },  -- Finder
  
  -- External
  -- c          Numi
  -- backspace  1Password
  -- Enter      Alfred
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
