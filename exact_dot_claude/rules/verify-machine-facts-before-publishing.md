# Verify Machine-Read Facts Against the Org Source-of-Truth Before Publishing

Promoted to a skill: invoke `documentation-plugin:docs-verify-machine-facts`
before a value read off your own machine (`scutil --dns`, `route get`,
`ifconfig`, `defaults read`, a local config file) lands in org / shared /
outward-facing documentation — it carries the misattribution failure mode and
its canonical break, the cross-check-against-the-IaC rule, the
mechanism-over-literal rewrite, the tunnel-vs-LAN attribution test for
multi-source readouts, and the re-derive-mutable-facts-at-publish-time check.
