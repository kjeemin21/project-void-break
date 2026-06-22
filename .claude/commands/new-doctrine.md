Create a new behavior doctrine preset for the fleet AI system.

Doctrine name: $ARGUMENTS

Follow these steps:
1. Create `resources/doctrines/{doctrine_name}.tres` with the doctrine parameters
2. Add the state machine definition in `scripts/fleet/doctrines/{doctrine_name}_doctrine.gd`
3. Define state transitions, trigger conditions, and priority ordering
4. Register the doctrine in the doctrine registry if one exists
5. Add an entry to `EDITOR_TODO.md` if any editor work is needed

Base the implementation on existing doctrine presets for consistency.
Reference the HFSM structure described in CLAUDE.md.
