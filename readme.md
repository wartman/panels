Panels
======

A simple format for writing comics.

Usage
-----

A detailed tutorial is coming soon.

For now, download and build Panels with Haxe. Then, try the following command from the `panels` directory:

`node dist/panels example/night -f odt`

...to generate an Open Document file from the `example/night.pan` example. You can also do `node dist/panels generate example/night -f html` to generate html.

If you want an example of Panels complaining about panel count, try:

`node dist/panels generate example/night -f odt --maxPanelsPerPage 2`

Note that right now the CLI is super basic and doesn't have any documentation, but that will change soon as well.
