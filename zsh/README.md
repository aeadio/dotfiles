My Zsh setup. I do not use any configuration frameworks, and I only use a handful of third-party plugins. The rest is bespoke. Since Zsh is one of my most heavily used tools, I put a good deal of effort into creating a configuration that is powerful, but still user friendly, and fast.

I've placed a particular emphasis on being well-organized and easy to navigate. Where possible, functionality is split into isolated configuration units within `.d` directories, so that individual changes can be effected piecemeal, in self-contained files, which are easy to change or (temporarily) remove.

### Subfolder structure (in the order they are loaded):

- `env.d`: Static environment exports. Variables that need to be available to third party applications. This is the only portion that is sourced always, including in non-interactive script shells. Bootstrapped by the file `env`.
- `pre.d`: Early initialization, such as loading compinit, prior to other configuration. Files are loaded in explicit alphanumeric order.
- `plugins.d`: Self-contained feature packages.
  - First-party plugins (mine) are installed as single files directly under `plugins.d/`.
  - Third-party plugins are installed as folders underneath `plugins.d/`. They are loaded if they contain a `.plugin.zsh` file. These are always loaded if present, even if not marked executable. Most of these are installed as Git submodules.
- `functions`: Utility functions used by the user, or by other portions of the configuration. These are [autoloaded](https://zsh.sourceforge.io/Doc/Release/Functions.html#Autoloading-Functions) as needed.
- `widgets`: Functions to be used as [ZLE widgets](https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html#User_002dDefined-Widgets). These are autoloaded, and automatically initialized as ZLE widgets.
- `rc.d`: Primary Zsh configuration. Sets shell options, aliases, decorates the prompt, etc.
- `post.d`: Late-stage changes, such as initializing any ZLE-impacting plugins after all custom widgets and ZLE configuration has taken place. Files are loaded in explicit alphanumeric order.

Other subfolders, not loaded automatically:

- `include`: Miscellaneous non-Zsh configuration files that need to be included as input to other commands during initialization.
- `vendor`: Third party plugins & other vendored-in components which will be loaded manually when needed.

Individual files can be enabled or disabled by toggling the execute permission -- most files are not sourced or autoloaded if they are not executable on startup.

### Startup

Primary bootstrap happens in `rc`, where each stage is wrapped in a named function to facilitate tracing and debugging. The variables `ZSHRC_PROFILE` and `ZSHRC_DEBUG` can be set to an integer (see below) to enable startup benchmarking, and print some information during start, respectively. Logs from either are also saved to the home directory.

The variable `ZSH` is set to the location of the Zsh config directory. Some helper functions are set up in `pre.d/util` to make writing configuration a bit more concise.

Finally, all files are automatically compiled with [zcompile](https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html#index-zcompile) once per day to speed up shell startup times (see `pre.d/zcompile`). This can be invoked manually via `compile-zshrc`, or by setting `ZSHRC_FORCECOMPILE` when starting up Zsh.

### Parameters used by startup
#### `ZSHRC_PROFILE`

1. Trace startup time until the full rc is finished loading
2. Trace startup time to just after the first prompt is drawn

#### `ZSHRC_DEBUG`

|   1   |   2   |   3   |   4   | Description                                |
| :---: | :---: | :---: | :---: | :----------------------------------------- |
|   x   |   x   |   x   |   x   | Warn when leaking globals                  |
|       |   x   |   x   |       | Print each file that is sourced/invoked    |
|       |       |   x   |       | Print lines of script as they are executed |
|       |       |       |   x   | Turn on XTRACE (ie, `set -x`)              |

#### `ZSHRC_FORCECOMPILE`

If set to any value, always recompiles all `zsh/` source files on startup.

### Components of interest

#### `rc.d/aliases`

Sets up common aliases. You won't find a ton of two- and three-letter aliases for all conceivable tasks. I use aliases mostly for the most frequently leveraged actions (viewing directory contents, opening an editor, etc), and rely on zsh-autosuggestions and smart completion for most other things.

On MacOS, Homebrew is automatically searched for any packages which are verion-pinned (i.e., installed as "package@version"), and aliases are automatically set up for all of that package version's binaries. This includes an emulated x86 instance of Homebrew on Apple ARM Macs, if present.

#### `rc.d/prompt`

I've tried to display quite a bit of useful information in the prompt while keeping it compact. Information which is not commonly referenced is elided when not needed. Ie, username is only shown if I'm `su`d to an uncommon user.

```
   .-- not shown unless it's different from my user or root
   |      .-- not shown unless connected over SSH
   |      |         .----------+-- responsively collapses if too long --------.
   |      |         |          |         .-- ahead/behind remote              |
   |      |         |          |         |       .- un/staged/merged/tracked  |
   |      |         |          |         |       `---.                        |
   |      |         |          |         |            \                       |
   v      v         v          v         v             v                      |
[[user][@host]:]directory [⨕gitbranch[:commits][ ⇄ localchanges]]             |
[[R] ][🯊[:awsprofile] ][⋮stack]»          ^-------------^--------------------'
  ^    ^      ^            ^
  |    |      |             `- displays the ZLE stack size (ie push-line)
  |    |       `-- AWS profile from Vault if not 'default'
  |     `-- MFA set by AWS Vault; red=expired, green=ok, yellow=unknown
   `-- if inside a Ranger shell
```

Because each of these components collapse when unused, a prompt in my home directory looks much less daunting:

```
~
» 
```

The prompt is always prepended by an empty line for visual padding between commands. The second line alone is used for the continuation prompt (PS2).

The color scheme is switched to a red, purple and yellow if running as root.

Git information is fetched asynchronously. See `functions/prompt:git-async` to see how the information is collected. The async plumbing is found at the end of `rc.d/prompt` and relies on backgrounding a task which sends the information back via [a new fd](https://zsh.sourceforge.io/Doc/Release/Redirection.html#Opening-file-descriptors-using-parameters), and a listener which waits for the response via [zle -Fw](https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html#index-zle).

Additionally, the XTRACE prompt (PS4) is set:

```
filename:linenum in funcname
→ ...
```

Each line is indented based on execution depth.

#### `plugins/bad-input`

Copy and pasting a command directly into the shell's line editor is a bad habit we all do once in a while. It can be particularly dangerous if the prompt of the command was `>`, where is may unexpectedly clobber a local file. Thankfully Zsh supported bracketed paste and does not invoke commands automatically when pasted, but this little plugin goes a step further.

When I try to execute a command that starts with a common prompt character, it refuses to run it -- instead, it loads the command back into the line editor, with the prompt character(s) removed, and sets a flag so `rc.d/prompt` can display a visual indicator that this has happened. I can strike enter again if I decided I really do want to run it.

#### `plugins/dynenv`

Creates `dynexport` and `dynunset` commands, for exporting global variables persisently, across shell instances. Variables exported in this way are saved to a global store (`$HOME/.dynenv` by default) and automatically sourced by all shells.

The motivation for this was being able to export session tokens such as MFA authentication, and have it available across all shells for that work session, and persist across reboots.

By default, all variables in the dynenv are sourced right before each new prompt. Therefore, when exporting a variable in one shell, you need to strike enter or ctrl-c in another shell instance to pick up the new variable.

If `fswatch` is installed, variables are instead sourced immediately in other shell instances, or at the next prompt if they are in the middle of executing a command.

#### `plugins/project-history`

When entering a Git repo (sub)directory, pivots the shell's history to one that is local to the Git project (via `<gitroot>/.history.user` histfile). This works fairly well as-is, but I'm investigating replacing this with a SQLite-backed global history mechanism instead, which would track (in addition to other useful things), which Git repo the command was invoked in, so that `widgets/fzf-history` can expose keybinds for swapping between global and per-project history search on the fly.

#### `functions/zp-*`

Small helper functions to faciliate installing and removing third-party Zsh plugins as Git submodules. Of note is `zp-try`, which clones the plugin(s) to a temporary folder, and starts up a new Zsh shell where they can be demoed. This relies on `bin/zshi`.

#### `rc.d/zle` & `widgets/*`

Keybindings are set up to mimic contemporary GUI applications. Actions such as undo/redo (ctrl-Z/Y), cut/copy/paste (ctrl-X/K/V) work as they would in desktop GUI apps (K is used in place of C, which cannot be rebound).

[fzf-tab](https://github.com/Aloxaf/fzf-tab) is used for the tab completion menu. Additionally, fzf-based menus are available for inserting files as arguments and searching history. History can also be searched by entering the beginning of a command, then using alt-up/down to search for all lines beginning with that input.

A shift-selection model is implemented that mimics how GUI applications allow selecting blocks of text. The mechanism is based on the [zsh-shift-select](https://github.com/jirutka/zsh-shift-select) plugin, but reimplemented and expanded with some additional capabilities. 

Holding shift and striking the arrow keys will select characters or lines behind or ahead of the current cursor. Additionally, ctrl+shift allows for selecting words ahead/behind, and alt+shift allows selecting to the beginning/end of the line (left/right) or entire input buffer (up/down).

The active selection will be replaced upon entering any other text, including pasting via ctrl-V. It can also be manipulated with some keybindings -- e.g., edited in-place with ctrl-E, quoted with ctrl-W, replaced by a list of files with ctrl-L, or replaced by tab completion with Tab.

A non-comprehensive list of useful keybindings:

- **ctrl-A** to move **a**fter the first word (as opposed to the start of the input -- use alt-left for that).
- **ctrl-F** to **f**ind in history using fzf.
- **ctrl-E** to **e**dit the current input in your `$EDITOR`. If some text is selected, edit that instead.
- **ctrl-L** to select a **l**ist of files using fzf, and insert them as an argument at the current position. If some text is selected, insert the list of files in place of the selected text instead.
- **ctrl-N** while the cursor is over a hypothetical path location to push the current input onto the ZLE input stack, then open a new input with `mkdir <foldername>` pre-filled. This is for situations where, eg, you begin typing the output destination for a command, only to realize the folder doesn't exist yet.
- **ctrl-P** to **p**ush the current input onto the ZLE input stack and open a fresh input. This is visually indicated by the prompt by a '⋮' character followed by the current stack depth.
- **ctrl-R** to toggle prefixing the current command with `doas` or `sudo` to run as **r**oot.
- **ctrl-S** to attempt to **s**pellcheck and correct the currently highlighted word.
- **ctrl-W** to quote the current line. If some text is selected, quote around the selection instead.

See `rc.d/zle` for a full list of keybinds. Custom [widgets](https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html#Zle-Widgets) (functions invoked by these keybinds) are implemented in `widgets/`. Keybindings specific to shift-select mode are found at the bottom.

Note that modifier keybindings, especially multi-modifier ones, may not work in all terminals.
