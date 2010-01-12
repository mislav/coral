Coral git repo manager
======================

Coral is an alternative to RubyGems when it comes to fetching opensource code and making it available
for loading in your app. Coral fetches git repositories from GitHub, organizes and stores them in a
predefined place ("~/.coral/" by default) and offers mechanisms for adding them to your `$LOAD_PATH`.

Why git instead of gems?
------------------------
* with git you don't have to wait for a release;
* you can fork a git repository, make changes and contribute back;
* with git you can ride an experimental branch of your favorite project;
* with git you have project history, which is good documentation by itself.


Getting started
---------------

Fetching a project:

    $ coral clone git://github.com/wycats/thor.git

    [or]

    $ coral clone wycats/thor

    [or even]

    $ coral clone thor

The repository will be cloned to "~/.coral/thor-wycats/". Now you can run some script that requires Thor:

    $ ruby -rcoral path/to/script.rb

And it will work. Similar to RubyGems, Coral overloads `Kernel#require` so that `require 'thor'` in your
code actually finds and loads "thor-wycats" you just cloned. If RubyGems is also loaded
(i.e. `ruby -rcoral -rubygems ...`) then first Coral will search for a missing library, then RubyGems.
If you load RubyGems first then it will have precedence over Coral.

Usage
-----

Now let's see what Coral is good for. Suppose we want to experiment with a stable release of Thor and edge
(master) at the same time. We already have master available; now let's check out a release:

    $ coral checkout thor v0.12.2

A new working copy for that existing git repository is now made in "~/.coral/thor-v0.12.2/" and the "v0.12.2"
tag is automatically checked out for us. You can open both working copies to inspect:

    $ $EDITOR ~/.coral/thor-*

You can also check what you have in your Coral index with:

    $ coral list

However, if you load coral to run scripts that require Thor, the master version will still be used because it
was created first. To specify which version (which checkout, to be precise) you want, use the `CORAL`
environment variable:

    $ CORAL=thor@v0.12.2 ruby -rcoral path/to/script.rb

This environment variable means that "~/.coral/thor-v0.12.2/lib/" directory will be pushed to `$LOAD_PATH` as
soon as Coral is loaded (which is right at the start, before your script executes).

To remove a specific working copy (checkout), use the `remove` command:

    $ coral remove thor@v0.12.2

It's time to see if anything changed upstream since we last cloned Thor. Use the `update` command:

    $ coral update thor

This will perform a `git pull` inside "~/.coral/thor-wycats/".

