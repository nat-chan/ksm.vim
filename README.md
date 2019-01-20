# K-Shoot MANIA.vim
[K-Shoot MANIA](https://www.kshootmania.com/en) is a music game for Windows.

ksm.vim provides some features that will help you to make charts.
## Features
### :KsmStart
Launch K-Shoot Editor and open the current buffer. This window will be placed under the control of Vim.
![KsmStart](https://github.com/nat-chan/ksm.vim/wiki/images/KsmStart.gif)
### :KsmGoto
Move the current line of Vim to the bar selected by K-Shoot Editor
![KsmGoto](https://github.com/nat-chan/ksm.vim/wiki/images/KsmGoto.gif)

## Installation

### For [vim-plug](https://github.com/junegunn/vim-plug)
```vim
" add this line to your .vimrc or init.vim
Plug 'nat-chan/ksm.vim'
```

### For manual installation
Extract the files and put ```autoload, plugin``` in ```%USERPROFILE%\_vim\``` or ```%LOCALAPPDATA%\nvim\```.

### Requirements
```vim
:echo has('python3') "returns 1
```

```python
pip install -r requirements.txt
```
