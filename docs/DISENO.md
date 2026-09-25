como# Documento de diseño (1 página)

## Concepto
Gestión de una colonia en 3D (estilo Banished) donde la amenaza son hordas de zombies.
Cámara isométrica desde arriba, estilo low-poly.

## Objetivo del proyecto
Aprender desarrollo de videojuegos con Godot 4 y compartir el resultado (web, itch.io).
Ritmo: ~3 h por semana.

## Bucle principal (core loop)
1. **Día**: los aldeanos recolectan recursos y construyen lo que ordenas.
2. **Noche**: llega una horda de zombies.
3. **Defensa**: muros y torres frenan a la horda; los aldeanos pueden morir.
4. **Crecimiento**: si sobrevives, la colonia crece y la siguiente horda es mayor.

## Condición de derrota / victoria
- Derrota: muere el último aldeano.
- Victoria (v1): sobrevivir 10 noches.

## Alcance de la versión 1 (lo mínimo jugable)
- Mapa pequeño fijo.
- 3 recursos: madera, piedra, comida.
- 5 edificios: casa, almacén, leñador, cantera, granja + muro y torre.
- Aldeanos autónomos con trabajo asignado.
- Oleadas de zombies crecientes.

## Fuera de alcance (por ahora)
Historia, árbol tecnológico, estaciones, misiones, multijugador, guardado de partida.

## Tecnología
- Motor: Godot 4, GDScript.
- Renderer: Compatibility (necesario para exportar a web).
- Assets: Kenney, Quaternius, KayKit (CC0), retoques en Blender.

## Hitos
1. Cámara isométrica + suelo + colocar un edificio (cubo) con el ratón.
2. Un aldeano que camina a un árbol, recoge madera y la lleva al almacén.
3. Zombies que aparecen de noche y persiguen aldeanos.
4. Muros y torres.
5. Bucle completo con cubos grises (prototipo gris jugable).
6. Sustituir cubos por assets low-poly.
