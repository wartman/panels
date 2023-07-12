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

[1]

We open on a dark and stormy night. This first panel here should be big -- 
really get that stormy atmosphere.

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
npx panels compile path/to/your/example -f html
```
If everything goes well, you should see `example.html` appear next to `example.pan`. Open it up in any browser and look around.

> You can also export an `fodt` file (which is in fact the default), which should be readable by most text processors. However that's still super early and the results aren't great yet.

You can also get information about your script without compiling it:

```
npx panels info path/to/your/example
```

This will give you some metadata (title and author) the current page count, the number of sections in your document (more on that below), and a breakdown of pages per section. Further information will likely be added as development continues.

Aiding Development
------------------

If you want to help with development, clone the repository and run `npm install` to set everything up, then run `npx haxe build.hxml` to compile Panels.

An important note: if you already have Haxe installed and attempt to run `haxe build.hxml`, you will almost certainly get an error about missing dependencies. Panels is using a package manager called [Lix](https://github.com/lix-pm/lix.client) to manage things, and it needs to be run through the Haxe executable it installs via npm. You might also consider installing the Lix VSCode plugin to make development quicker.

Documentation
-------------

> Note: These docs are still a work in progress, here more so I remember what everything does than anything else. In addition, they currently assume you have some familiarity with programming and CLI ("Command Line Interface") programs. Hopefully as Panels gets better this will improve!

Panels' syntax is designed to be simple, readable and straightforward.

### Comments

Comments can go anywhere, and they're ignored and removed completely at compile time. To create a comment, just start them with `/*` and end with `*/`.

```
/* Like this! */
```

For simplicity, Panels currently only has this one kind of comment.

> Incidentally, nesting comments (like `/* this /* is */ fine */`) is also supported. 

### Frontmatter

At the top of every `.pan` script (aside from any comments) is the *frontmatter*. This is a simple list of information about your script, like the title and the author.

```pan
title: Example Comic Script
author: Peter Wartman
version: 1
```

The frontmatter section goes from the start of the document to the first *break*. You can skip the frontmatter in your document by starting it with a break. 

### Breaks

There are two kinds of *breaks* in Panels: *page* breaks and *section* breaks.

Page breaks are indicated by three dashes:

```
---
```

Note that this means a new *comic* page, not a new page in the actual script. When you compile your `.pan` file to something like an `.odt` or `.doc`, you'll probably have at least a few comic pages that take up more than one page in the script.

Note that Panels doesn't give you a way to manually write page numbers here. That's by design -- you're probably going to be moving pages around and deleting them as you create your script. Rather than forcing you to laboriously go through your file and update the page numbers whenever you make a big change, Panels will handle it for you at compile time. In your compiled file, every page will start with something like:

```
Page 1 - 3 Panels
```

...and this will all be handed automatically (note that we'll get to panels in a second).

The other kind of break is a *section* break. Sections are just a generic name Panels uses to mean a *group of pages*. We could call these chapters, but they can be anything you want. Their main purpose is to make organizing your script a little easier. By default, they don't even get included when your script is compiled.

> The `--includeSections -s` flag can be used to toggle this, although that behavior may not be working for all formats quite yet.

Section breaks are indicated by three equals signs (`=`):

```
===
```

Sections *may* be unnamed, but you're strongly encouraged to name them:

```
===
Chapter 1
---
```

A section name can (currently) only be one line long, and must be followed by a page break. Note that you'll need to include the page break even if you don't add a title:

```
===
---
```

> Note: These rules are probably too fiddly, and this is one of the areas most likely to change.

You can have as many comments and random whitespace as you want around your section title, however.

```
===


Chapter 1

/* this is fine */
---
```

One additional break is the *two-page spread*. It looks like this:


```
---|---

[1]

This is a two page spread!
```

This works anywhere a normal page break would, however Panels will -- by default -- check to make sure that a two-page spread will actually work in the location given. This just means checking that the left-hand page is *even-numbered*.

> Note: This may change in the future.

### Panels

Every page in Panels must have at least one panel. It's in the name, after all.

There are two ways to write panels: *automatic* and *manual*. 

For automatic panels, use empty brackets:

```
[]
```

For manual ones, use a number:

```
[1]
```

You can mix and match both methods on the same page -- Panels will figure things out at compile time.

> Note that you can use the `--checkPanelOrder -o` flag to have Panels warn you if panel numbers get out of order.

### Panel Descriptions

This is all the stuff that goes inside your panels that *isn't* dialog. Panels is pretty markdown inspired here, so a lot of the stuff that works there (`*italics*`, `**bold**`, `_like this_`, `__too__`, even `[links](to/some/url)`) will work here too.

### Dialog

Dialog is indicated by a name (of any number of words) in ALL CAPS. You can optionally add VO/OFF-PANEL or other details in the parens after the name. 
    
Also note the "(cont.)". This is required if we have more than one line of dialog -- otherwise, a newline indicates to Panels that we're done with Dialog and it will return to Panels Description mode.

Note that indentation is optional, but looks nice.

```
    FRED FREDSON (OFF)
    Hey Bob, it sure is _stormy_ out here.
    (cont.)
    Kind of *scary* 
```

In the following example, `KRRKOOM` could be interpreted as a character name by Panels -- we can add an escape character ("\") to make sure that it won't be confused.

```
    SFX (Lightning)
    \KRRKOOM
```

... although in this case Panels is smart enough to know that it's actually not needed, as its written in a place where it will always be interpreted as dialog text, so the following will still work:

```
    SFX (Lightning)
    KRRKOOM
```

If, for whatever reason, you have a name that can't fit the ALL CAPS format (or if you just don't like the way it looks), use can use the alternate `@Name` format:

```
    @ fred fredson (off)
    Hey Bob, it sure is _stormy_ out here.
    (cont.)
    Kind of *scary* 
```

All the same markdownish syntax you can use in panel descriptions will work in dialog bodies too, incidentally.

Dot Panels
----------

You may have noticed that Panels has a *lot* of cli flags. It would be annoying to have to write these every time, so Panels can use a simple `.panels` configuration file. Simply place this anywhere in a directory above
your script file and Panels will load it when you run the compiler. You can ignore a `.panels` with the CLI flag `--ignoreDotPanels -i`.

> Note: Eventually you'll be able to override .panels configuration options with CLI flags, but that's not working yet.

VSCode Integration / Syntax Highlighting
----------------------------------------

Coming Soon ™