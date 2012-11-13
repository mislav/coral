Coral
=====

Coral is a set of shell commands that help working with open-source projects,
Ruby apps, GitHub and more.

Coral is a [sub][] in the way its structure grew out of rbenv's.

Installation
------------

~~~ sh
git clone git://github.com/mislav/coral.git ~/.coral

# display instructions how to edit shell configuration:
~/.coral/bin/coral init

# later, when you've reloaded the new shell configuration:
coral doctor
~~~

See `coral help` for available commands.


Features
--------

### Organizing git clones of GitHub repos

If you read the code or contribute to a number of open-source projects, you
might have become tired of picking a clone destination for each of those
projects.

Coral can clone repos for you and keep them organized in its internal directory
structure:

~~~ sh
coral clone bootstrap             # will search GitHub and pick the first result
coral clone twitter/bootstrap     # if you want to be explicit
coral path bootstrap              # display the path of where Bootstrap is locally

coral cd bootstrap                # cd into Bootstrap's project directory
git tag | coral sort-versions     # display available versions

coral checkout bootstrap v2.2.0   # check out a new working copy for Bootstrap v2.2.0
coral cd bootstrap@v2.2.0         # cd into the new working copy

coral list bootstrap              # list available working copies of Bootstrap
~~~

### Working with RubyGems and Bundler

The bonus of all Coral gem commands are that they are Bundler-aware; i.e. when
you give them a name of the gem, they first search for it in the current bundle
and then in globally installed gems. This helps you with inspecting versions of
gems that your project currently uses.

~~~ sh
coral gem-dir activesupport       # print the root directory of a gem
coral gem-open activesupport      # open gem's source code in the editor
coral gem-browse sinatra          # open Sinatra's home page in the browser
coral gem-browse-project sinatra  # open Sinatra's project page on Github

coral bundle-ack -w redirect_to   # search across all gems in the bundle
~~~

### Render documentation files to HTML

~~~ sh
# render any markup the same way GitHub.com does HTML:
coral github-markup path/to/README.md >> readme.html

# `github-markup` output + styles & syntax highlighting; pipe to browser
coral render-markup path/to/README.md | bcat
~~~

### Opening source code in editor

Handy shortcuts for opening a project's directory in your favorite text editor.
The `gem-open` command also has a nice feature for preloading the README file
for you, if it exists:

~~~ sh
coral gem-open activesupport      # open gem's source code & README in the editor
coral open-dir path/to/project    # open a project in $EDITOR
~~~

You should have your shell configured like so:

* Vim:

        EDITOR=vim
        GEM_EDITOR=mvim   # or "gvim" on Linux

* Sublime Text 2:

        EDITOR='subl -w'
        GEM_EDITOR=subl

* TextMate:

        EDITOR='mate -w'
        GEM_EDITOR=mate

### Miscellaneous unix goodies

~~~ sh
coral sort-versions               # sort version numbers on STDIN
coral fetch-url <url>             # fetch URL and cache the result for 24 hours
coral parse-json                  # parse JSON and output in flat, line-based format
~~~


  [sub]: https://github.com/37signals/sub
