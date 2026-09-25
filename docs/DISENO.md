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
8. Decisiones y tensión: aviso de horda, curva de dificultad, guía y mejoras al amanecer.

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

## Hito 8: decisiones y tensión
Objetivo: que el jugador **tome decisiones** y sienta que cada noche es un reto que
puede preparar. Tres piezas, en este orden:

### 8.1 Aviso de horda (estrategia)
- Al amanecer se decide cómo será la noche siguiente: **cuántos zombies y por qué lado(s)**
  (norte, sur, este, oeste).
- Se anuncia durante todo el día en el HUD: *"Esta noche: 6 zombies desde el NORTE"*.
- En el borde del mapa, en cada lado de ataque, aparece un **marcador rojo** que late.
- A falta de 15 s para anochecer: aviso *"¡La horda llega en 15 s!"*.
- Los zombies aparecen **solo por los lados anunciados** (en una franja, no por todo el borde).
- Así importa **dónde** construir muros y torres.

### 8.2 Curva de dificultad (equilibrio)
- Tabla fija de oleadas (en vez de la fórmula base + extra por noche):

  | Noche | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
  |---|---|---|---|---|---|---|---|---|---|---|
  | Zombies | 2 | 3 | 5 | 6 | 8 | 10 | 12 | 14 | 17 | 20 |
  | Lados | 1 | 1 | 1 | 1 | 2 | 2 | 2 | 2 | 3 | 3 |

- La noche 1 se puede sobrevivir sin construir nada (enseña cómo funciona la noche);
  a partir de la 3 hacen falta torres; a partir de la 5, defender dos frentes.
- Los zombies hacen **menos daño a edificios** que a aldeanos, y el almacén aguanta más:
  refugiarse debe ser útil, no una trampa.
  - Zombies: 10 de daño a aldeanos, 4 a edificios. Almacén: 400 de vida.
- **Al amanecer se reparan todos los edificios**: cada noche empieza con todo entero.

### 8.3 Mejora al amanecer (progreso y "una noche más")
- Tras sobrevivir una noche, el juego se pausa y ofrece **3 cartas al azar**; eliges 1.
- Cartas (efecto permanente durante la partida):

  | Carta | Efecto |
  |---|---|
  | Arqueros expertos | Torres +30 % de daño |
  | Vigías | Torres +2 de alcance |
  | Muros reforzados | Muros, torres y edificios +50 % de vida |
  | Brazos fuertes | Aldeanos +2 de carga por viaje |
  | Buena cosecha | Granjas +50 % de comida |
  | Racionamiento | Cada aldeano come 1 en vez de 2 |
  | Pies ligeros | Aldeanos +25 % de velocidad |
  | Carromato de suministros | +40 madera y +25 piedra al momento |

- Las cartas que ya no aportan nada (p. ej. Racionamiento ya elegida) no vuelven a salir.

### 8.4 Guía de primeros pasos (hecha antes que 8.3)
- Panel arriba a la derecha con **un consejo a la vez**, el primero que falta por cumplir:
  1. Cantera (piedra) · 2. Granja (comida, hambre) · 3. Torre (defensa) ·
  4. Casa (nacimientos) · 5. Muros en el lado de la franja roja.
- Cada paso se cumple al construir ese edificio; al completarlos, la guía desaparece.

### Hecho cuando
- Durante el día siempre sabes qué viene esa noche y por dónde.
- Un jugador nuevo sobrevive la noche 1 sin saber nada; la noche 5 exige haber
  defendido los lados anunciados.
- Cada amanecer eliges una mejora y se nota en la partida.
- Exportado de nuevo a itch.io.
