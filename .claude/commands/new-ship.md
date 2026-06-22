Create a new ship class for Project Void Break.

Ship name: $ARGUMENTS

Follow these steps:
1. Create `scripts/ships/{ship_name}.gd` extending the base ship class
2. Create `resources/ships/{ship_name}_stats.tres` with default stat values
3. Implement all required methods from the base ship interface
4. Add an entry to `EDITOR_TODO.md` for:
   - Creating the scene file with proper node hierarchy
   - Setting up collision shape
   - Attaching the script

Use static typing, @export for tunable stats, and follow the project's GDScript conventions.
