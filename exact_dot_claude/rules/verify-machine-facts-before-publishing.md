# Verify Machine-Read Facts Against the Org Source-of-Truth Before Publishing

Promoted to a skill: invoke `documentation-plugin:docs-verify-machine-facts`
before a value read off your own machine (`scutil --dns`, `route get`,
`ifconfig`, `defaults read`, a local config file) lands in org / shared /
outward-facing documentation.
