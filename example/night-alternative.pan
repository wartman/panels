/* This is a comment! It will be ignored from the output. These can be handy to write notes to yourself or to temporarily remove sections of a document. Also, /* comments can be nested! */ */

/* At the start of the file we have a place for "frontmatter" -- the title of the script, the author, etc. */

Title: Example Comic Script
Author: Peter Wartman
Version: 1

/* Three equals (===) indicate a Section. These are mostly useful for breaking up a document into parts */

===

/* Sections may include only one line of text -- this will be used as the section title. Sections may also have any amount of white-space or comments. */

Chapter 1

/* These three dashes (---) indicate a page break. We don't manually number pages -- just include these between each of your pages. */

---

/* There are two ways to number panels: a pair of empty square brackets ("[]")  will tell Panels to automatically number the panels, while you can also provide your numbers manually (e.g. "[1]"). You can mix and match these numbers in a Panels document, but NOT on the same page. */

[]

/* Everything after a panel indicator and before dialog is a Panels Description. */

We open on a dark and stormy night. This first panel here should be big -- really get that stormy atmosphere.

/* Note the link here -- use this if you need to include references for your artist */

Maybe like [this](some/url.png) or something?

/* The following is a caption, which is simply marked by typing CAPTION in all caps. You can optionally add a location/time after it in parens. */

CAPTION (Night)
A dark and stormy night...

[]

Fred turns to his friend. He looks around nervously.

    /* Mark dialog by typing a character name (of any number of words) in ALL CAPS. You can optionally add VO/OFF-PANEL or other details in the parens after the name. 
    
    Also note the "(cont.)". This is required if we have more than one line of dialog -- otherwise, a newline indicates to Panels that we're done with Dialog and it will return to Panels Description mode.

    Note that indentation is optional, but looks nice.
    */

    FRED FREDSON (OFF)
    Hey Bob, it sure is _stormy_ out here.
    (cont.)
    Kind of *scary* 

/* Note that indentation for dialog is optional -- just use it if it helps you keep track of things. In addition, you can use `@ name` as an alternative way to write characters, if you don't like ALL CAPS. */

@Bob Bobsman (OFF)
You got that right, friend.

[]

There is a long and awkward silence.

---

[]

A lightning bolt comes out of nowhere and incinerates both characters. It is grisly and a bit horrifying.

But also funny.

    /* Note that `KRRKOOM` could be interpreted as a character name by Panels -- we can add an escape character ("\") to make sure that it won't be confused. In this case it's actually not needed, as its written in a place where it will always be interpreted as dialog text.  */
    SFX (Lightning)
    \KRRKOOM

[]

Fade to black.

In a comic.

You can figure it out.

===

/* You can have as many sections as you want in your script, wherever you want. Just note that sections will create page breaks, just like using `---` will. */

Chapter 2

---

[]

Suddenly more things happen.
