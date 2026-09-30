# Harbor Year

A year-one yacht-club sim. You are the manager. Each season you pick one spend and one political move, then live with the vote, the weather, and the books. The club is fictional. Cash under zero closes the doors. After Fall, fewer than 140 members does too.

Godot 4, GDScript, placeholder art.

## Run the game

```
godot --path /workspace
```

The binary used here is Godot 4.7.2:

```
/home/ubuntu/.local/bin/godot --path /workspace
```

The window title is Harbor Year. The year starts on a winter morning. Autosave is written at each season start to `user://harbor_year.json`.

## Headless checks

```
godot --headless --path /workspace -s res://tests/sim_checks.gd
```

The checks force the season die. A quiet year should end near $51,250 and still be solvent. A high deductible plus a bad storm should end insolvent. A full dredge, chasing Dan, and a passed recruit vote should end solvent, with boats allowed to move when the channel is open and the season is not Winter.
