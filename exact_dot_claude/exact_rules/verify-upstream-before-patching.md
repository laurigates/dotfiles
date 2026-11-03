# Verify Upstream Before Patching Vendored / Installed Code

Promoted to a skill: invoke `git-plugin:git-upstream-fix-check` before patching
third-party code that lives inside the project — a vendored library, a
tarball-installed package (ComfyUI custom node, pip wheel, `npm pack`), a fork
checkout, or checked-in generator output — to find out whether the bug is already
fixed upstream.
