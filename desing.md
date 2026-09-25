# Documento de diseño (1 página)

## Concepto
Gestión de una colonia en 3D (estilo Banished) donde la amenaza son hordas de zombies. Cámara isométrica desde arriba, estilo low-poly.

## Objetivo del proyecto
Aprender desarrollo de videojuegos con Godot 4 y compartir el resultado (web, itch.io). Ritmo: ~3 h por semana.

## Bucle principal
1. Día: los aldeanos recolectan recursos y construyen.
2. Noche: llega una horda de zombies.
3. Defensa: muros y torres frenan a la horda.
4. Crecimiento: si sobrevives, la colonia crece y la siguiente horda es mayor.

## Derrota / victoria
- Derrota: muere el último aldeano.
- Victoria (v1): sobrevivir 10 noches.

## Alcance v1
Mapa pequeño fijo · 3 recursos (madera, piedra, comida) · casa, almacén, leñador, cantera, granja, muro, torre · aldeanos autónomos · oleadas crecientes.

## Fuera de alcance
Historia, árbol tecnológico, estaciones, misiones, multijugador, guardado.

## Tecnología
Godot 4 + GDScript · renderer Compatibility (para exportar a web) · assets CC0 (Kenney, Quaternius, KayKit) + Blender · MCP: Coding-Solo/godot-mcp.

## Hitos
1. Cámara isométrica + suelo + colocar un edificio (cubo) con el ratón.
2. Aldeano que recoge madera y la lleva al almacén.
3. Zombies de noche que persiguen aldeanos.
4. Muros y torres.
5. Prototipo gris jugable completo.
6. Sustituir cubos por assets low-poly.

Proyecto local: W:\banished (docs/DISENO.md)