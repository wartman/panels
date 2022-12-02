Panels
======

A simple format for writing comics.

Usage
-----

A detailed tutorial is coming soon.

For now, download and build Panels with Haxe. If you have the `Lix` plugin installed in VSCode, you should just be able to run a build command and be good to go. Otherwise, run `npm install` to set everything up and then run `npx haxe build.hxml` to compile panels.

Then, run the following command from the `panels` directory:

`node dist/panels`

You should see a list of commands and instructions about their use. To test things out, try generating one of the example files:

`node dist/panels generate example/night -f html`

...or running any of the other subcommands (like `info`) on the examples.
