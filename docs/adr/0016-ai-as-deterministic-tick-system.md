# AI as a deterministic tick system

The AI runs as a system in the tick pipeline (between `apply-orders!` and other systems), not as a separate thread or external process. It reads live world state and issues orders that apply next tick — same one-tick latency as human input.

This preserves lockstep determinism: both players simulate the same AI, get the same orders. A non-deterministic AI (ML, random) would break lockstep. The AI must be pure: same world state → same orders.

For v1, the AI is scripted (fixed build order with guards). For v2+, reactive AI must still be deterministic given identical input.
