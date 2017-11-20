# Installation

- Rascal MPL:
  - Requires Eclipse for RCP/RAP developers; see [Eclipse package
    downloads].  Choose Eclipse Neon.
  - [Rascal update site].

[Eclipse package downloads]: https://www.eclipse.org/downloads/eclipse-packages/
[Rascal update site (stable)]: https://update.rascal-mpl.org/stable/

# Use

In Eclipse, click `Rascal → Start Console`.  This starts a Rascal
terminal/console in the lower pane.  In the terminal, type the
following:

```
import Server;
serveIt()
```

This imports `src/library/Server.rsc` and runs the function
`serveIt()`.  The server is now running and can be accessed on localhost
in your browser.  Type this in the address bar:

```
http://localhost:8088/
```

You should now see some JSON data.
