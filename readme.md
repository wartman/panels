Panels
======

A simple format for writing comics.

Usage
-----

A detailed tutorial is coming soon.

For now, download and build Panels with Haxe. If you have the `Lix` plugin installed in VSCode, you should just be able to run a build command and be good to go. Otherwise, run `npm install` to set everything up and then run `npm run build` (or `npx haxe build.hxml`) to compile panels.

Then, try the following command from the `panels` directory:

`node dist/panels example/night -f odt`

...to generate an Open Document file from the `example/night.pan` example. You can also do `node dist/panels generate example/night -f html` to generate html. To just get a page count, try `node dist/panels count example/night`.

If you want an example of Panels complaining about panel count, try:

`node dist/panels generate example/night -f odt --maxPanelsPerPage 2`

Note that right now the CLI is super basic and doesn't have any documentation, but that will change soon as well.
