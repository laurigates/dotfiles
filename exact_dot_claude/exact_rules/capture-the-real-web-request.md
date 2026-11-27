---
reviewed: 2026-11-24
---

# Replaying a Web Form Over HTTP — Capture the Request the Browser Sends

A client that posts to a server-rendered web app must copy the request the
page sends, not the request the form's HTML suggests. Page script can change
the request between the form and the wire, and such a server often answers a
request it does not recognise with HTTP 200 and saves nothing.

Before writing or fixing such a client:

- **Record one real submission** in the browser (DevTools Network, or a wrapper
  around `XMLHttpRequest`/`fetch` on the page) and copy from it:
  - the charset of the body. A page served as ISO-8859-15 posts non-ASCII
    field values in that charset, and a server may dispatch on such a value
    (a submit button's label);
  - the headers script adds, `X-Requested-With` above all;
  - which fields are sent. Script may drop a field the form contains, or send
    a default the HTML leaves empty.
- **Build the body from the fields of the live page**, overriding the ones you
  set, so a field the app adds later does not break the client silently.
- **Keep the server's answer.** Put the response text into the error instead
  of discarding it; "nothing was saved" with no answer attached takes several
  live attempts to diagnose.
- **Check the side effect, not the status code**: re-read the record the post
  was meant to create.

Evidence: `docs/rules-evidence.md` § capture-the-real-web-request.md.
