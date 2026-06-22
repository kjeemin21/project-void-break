Create a new ship module for Project Void Break.

Module name and description: $ARGUMENTS

Follow these steps:
1. Create `resources/modules/{module_name}.tres` with module stats and metadata
2. Create `scripts/modules/{module_name}_module.gd` with the module logic
3. Implement the module interface (apply/remove effects, stat modifications)
4. If the module affects fleet AI behavior, document how it interacts with the doctrine system
5. Add drop table entry or note where this module should appear in loot tables
6. Add an entry to `EDITOR_TODO.md` if any editor work is needed (e.g., visual indicators)

Follow the composition pattern — modules should be attachable to any compatible ship.
