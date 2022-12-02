Panels
======

A simple format for writing comics.

It looks something like this:

```panels
title: Example Comic Script
author: Peter Wartman
version: 1

===

Chapter 1

---

We open on a dark and stormy night. This first panel here should be big -- really get that stormy atmosphere.

Maybe like [this](some/url.png) or something?

    CAPTION (Night)
    A dark and stormy night...

[2]

Fred turns to his friend. He looks around nervously.

    FRED FREDSON (OFF)
    Hey Bob, it sure is _stormy_ out here.
    (cont.)
    Kind of *scary* 

    BOB BOBSMAN
    You got that right, friend.


```

> Note: Not much documentation right now. Take a poke around the source code if you're interested, and I should have more information up soon!

Usage
-----

Eventually Panels will have a plugin for VSCode, syntax highlighting, and all that good stuff. Right now it's still early days.

If you want to try it out, you can install Panels via npm. It's not ready to be published yet, but you can still get it from github.

```
npm install github:wartman/panels
```

Just use `npx panels` (or simply `panels`, if you did a global install) to run the CLI. You should see a list of commands you can play around with.

As an experiment, try copying the example at the top of this readme into a file named something like `example.pan`. Then run the following command:

```
npx panels generate path/to/your/example -f html
```
If everything goes well, you should see `example.html` appear next to `example.pan`. Open it up in any browser and look around.

> You can also export an `fodt` file (which is in fact the default), which should be readable by most text processors. However that's still super early and the results aren't great yet.

You can also get information about your script without generating any output.

> This currently is only a page count, but I think more information will be available soon.

```
npx panels info path/to/your/example
```

Development
-----------

If you want to help with development, clone the repository and run `npm install` to set everything up, then run `npx haxe build.hxml` to compile Panels.

An important note: if you already have Haxe installed and attempt to run `haxe build.hxml`, you will almost certainly get an error about missing dependencies. Panels is using a package manager called [Lix](https://github.com/lix-pm/lix.client) to manage things, and it needs to be run through the Haxe executable it installs via npm. You might also consider installing the Lix VSCode plugin to make development quicker.
