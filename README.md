# dotfiles

My dotfiles. I use a mix of MacOS and Linux. There is a separate branch for each, with changes occasionally cherry-picked from one to the other.

If you're just browsing around, the most interesting part is [my Zsh configuration](https://github.com/aeadio/dotfiles/tree/linux/zsh). I do not use any configuration frameworks, and I only use a couple of third-party plugins. The rest is bespoke.

Most functionality is hand-crafted in pure Zsh, and the overall codebase is structured like an application. My goal is to create a shell configuration that is powerful and user-friendly, but still hackable and reasonably fast.

Some things to look at,

- You can find [several small in-house Zsh plugins](https://github.com/aeadio/dotfiles/tree/linux/zsh/plugins.d) as self-contained files under plugins.d/
  - [project-history](https://github.com/aeadio/dotfiles/blob/linux/zsh/plugins.d/project-history) implements separate shell histories within Git project repos
  - [dynenv](https://github.com/aeadio/dotfiles/blob/linux/zsh/plugins.d/dynenv) implements a novel mechanism for exporting variables _across shell instances_ instantaneously. Useful for, eg, exporting an access token in one shell, and immediately using it in another one.
- Zsh's ZLE line editor has been [extensively configured](https://github.com/aeadio/dotfiles/blob/linux/zsh/rc.d/zle), including many [custom widgets](https://github.com/aeadio/dotfiles/blob/linux/zsh/widgets) that implement functionality such as,
  - GUI-like shift-selection (including copy/paste to the system clipboard)
  - Quickly navigating [directories](https://github.com/aeadio/dotfiles/blob/linux/zsh/widgets/navigate-gitroot-or-home) and [history](https://github.com/aeadio/dotfiles/blob/linux/zsh/widgets/fzf-history)
  - Quickly [selecting files/parameters](https://github.com/aeadio/dotfiles/blob/linux/zsh/widgets/fzf-select-files)
  - MacOS "Quick Look"-like [previewing of command parameters](https://github.com/aeadio/dotfiles/blob/linux/zsh/widgets/open-path-or-pwd)
  - And more
- The custom [prompt](https://github.com/aeadio/dotfiles/blob/linux/zsh/rc.d/prompt) is fully-featured, including,
  - Git branch & status
  - Auto-collapsing directory display based on terminal width
  - Auto-collapsing username and hostname which are only displayed when needed (su'd to another user, or connected to a remote machine)
  - Useful information about the shell environment, such as the size of the Zsh ZLE input stack; the current SHLVL depth; or whether or not our shell was spawned from within a file manager
  - Minimalistic design that displays only the information that's needed in a clean way, with clear visual padding
- Performance optimizations, such as,
  - [Compiling compinit definitions asynchronously](https://github.com/aeadio/dotfiles/blob/linux/zsh/pre.d/10-compinit-async)
  - [Pre-compiling Zsh source files asynchronously](https://github.com/aeadio/dotfiles/blob/linux/zsh/pre.d/99-zcompile)
- Most shell configuration happens in [rc.d/](https://github.com/aeadio/dotfiles/tree/linux/zsh/rc.d)
- Primary bootstrapping happens in [rc](https://github.com/aeadio/dotfiles/blob/linux/zsh/rc), including functionality for profiling and debugging startup time.

## How do I use them?

These are my personal dotfiles. If you find something useful here, you are free to use any or all of it under the terms of [0BSD](https://opensource.org/licenses/0BSD), except for any files/folders which have their own license included or are attributed to another author.

Feel free to fork, but make it your own. I make no effort to generalize my setup for consumption and/or remove any assumptions or personal choices.
