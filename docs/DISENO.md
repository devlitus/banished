# Documento de diseño (1 página)

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
7. Publicar en la web (itch.io).

## Hito 7: publicar en la web (itch.io)
Objetivo: que cualquiera pueda jugar desde el navegador en una página de itch.io.
Coste: 0 € (juego gratuito; itch.io no cobra por publicar ni alojar).

### Pasos
1. **Plantillas de exportación**: instalar las de Godot 4.7.2
   (Editor → Gestionar plantillas de exportación → Descargar e instalar).
2. **Preset "Web"**: Proyecto → Exportar → Añadir → Web.
   - Exportar sin hilos (*Thread Support* desactivado): así no hace falta
     SharedArrayBuffer y funciona en cualquier navegador y en itch.io sin trucos.
   - Salida: `build/web/index.html` (la carpeta `build/` no se sube al repositorio).
3. **Probar en local**: abrir la exportación con un servidor local
   (el botón "Ejecutar en navegador" del editor, o `python -m http.server`).
   Comprobar:
   - Carga sin errores en la consola del navegador (F12).
   - La navegación se recalcula al construir/derribar muros (sin hilos va en el hilo principal).
   - Rendimiento aceptable con la horda más grande (noche 10).
   - Ratón, teclado, zoom y botones de la interfaz funcionan.
4. **Arreglar lo que falle** en web (pantalla de carga, tamaño de ventana, rendimiento...).
5. **Empaquetar**: comprimir el *contenido* de `build/web/` en un `.zip`
   (con `index.html` en la raíz del zip).
6. **Página en itch.io**:
   - Crear proyecto: tipo *HTML*, subir el zip y marcar *This file will be played in the browser*.
   - Tamaño del visor: 1280×720, con botón de pantalla completa.
   - Descripción, controles, capturas y créditos (Kenney, CC0).
   - Precio: gratis (opcional: "paga lo que quieras" con mínimo 0).
   - Publicar primero como *Draft* o *Restricted*, probar, y luego *Public*.
7. **Commit** del preset de exportación y de los cambios necesarios.

### Hecho cuando
El juego se puede jugar entero (de la noche 1 a la victoria o la derrota)
desde el enlace de itch.io, en Chrome y Firefox.
