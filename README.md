# 🥚 Huevos de Bloques

Los 16 huevos hechos con ladrillos, armados por código en Roblox a partir de las fotos de
`Escritorio/Huevos`. Por ahora es una galería para verlos: más adelante se suman al juego de criaturas.

## Cómo verlos

```bash
rojo serve
```

En Studio: abrí un **Baseplate**, conectá el plugin Rojo (**Plugins → Rojo → Connect**) y dale a **Play**.

- Usa el Kit de `../RobloxDev/Kit/src`, así que las dos carpetas tienen que estar juntas en el escritorio.
- Los huevos están en ronda alrededor del punto de aparición. El que tenés cerca gira solo para que lo veas de todos lados.

## Los huevos

| Huevo | Qué lo distingue |
|---|---|
| 🐴 Caballito de Mar | De violeta a amarillo de arriba abajo, con un remolino al frente y aletas a los costados |
| 🌵 Cactus | Manchas de dos verdes, espinas y un brazo con flor |
| 🍬 Chicle | Rosas mezclados, muchos ladrillos lisos |
| 🪸 Coral | Rombos concéntricos al frente y ramas de coral |
| ⚡ Eléctrico | Franjas en diagonal amarillas, verdes y azules, con chispas |
| ⭐ Estrella | Mosaico azul y verde, estrella amarilla y puntos redondos |
| 🔥 Fuego | Llama al frente y fuego arriba |
| 🐟 Pez Linterna | Azul oscuro y violeta, boca en V, puntos que brillan y pie blanco |
| 🪨 Roca Flamante | Mármol rojo y naranja, con piedras |
| 🟫 Tierra | Marrones, más claros arriba |
| ⛈️ Tormenta | Azul noche y negro, con cúpulas |
| 🌴 Tropical | Marrón con cinturón verde y hojas |
| 🌿 Vegetal | Verdes con un rayo amarillo al frente |
| 🌨️ Ventisca | Celestes y blancos, con una franja blanca |
| 🌋 Volcán | Piedra negra con grietas de lava que brillan |
| 🧊 Hielo | Celestes, rombo blanco al frente y ladrillos transparentes |

## Cómo está hecho

| Archivo | Qué hace |
|---|---|
| `src/shared/Eggs.luau` | Los 16 huevos: paleta, cómo se pinta cada ladrillo, adornos y efectos |
| `src/shared/EggBuilder.luau` | Arma la cáscara por capas, la pinta y junta las celdas iguales en ladrillos de 1 a 4 |
| `src/shared/EggDecor.luau` | Adornos: aletas, espinas, brazo de cactus, coral, estrella, hojas, cúpulas, puntos y pie |
| `src/shared/Paint.luau` | Ayudas para pintar (elegir color por peso, líneas) |
| `src/server/Main.server.luau` | La galería |
| `src/client/Spin.client.luau` | Hace girar los huevos cercanos |

**Agregar un huevo:** copiá uno de `Eggs.list` y cambiale el `id`, la paleta y la función `paint`.
`paint(c)` recibe la posición de cada ladrillo (`c.t` = altura de -1 a 1, `c.u`/`c.v` = posición
sobre el frente, `c.noise` = manchas) y devuelve el nombre de un color de la paleta. La forma del
huevo (ancho, capas, qué tan panzón) está en `EggBuilder.Shape`.

Los ladrillos no llevan ningún logo ni marca: son solo studs.
