# 🥚 Huevos de Bloques

Los huevos hechos con ladrillos, armados por código en Roblox a partir de las fotos de
`Escritorio/Huevos`. Por ahora es una galería para verlos: más adelante se suman al juego de criaturas.

## Cómo verlos

```bash
rojo serve
```

En Studio: abrí un **Baseplate**, conectá el plugin Rojo (**Plugins → Rojo → Connect**) y dale a **Play**.

- Usa el Kit de `../RobloxDev/Kit/src`, así que las dos carpetas tienen que estar juntas en el escritorio.
- Los huevos están en anillos alrededor del punto de aparición. El que tenés cerca gira solo para que lo veas de todos lados.

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
| 💧 Agua | Azules con olas trenzadas celestes y turquesa |
| 🟤 Barro | Marrones parejos |
| ☁️ Nube | Blancos y celestes pálidos, óvalos a los costados y bultos de nube |
| 🌶️ Picante | Amarillo arriba, naranja con pintas en el medio, rojo abajo, con cabito y hojas |
| 🐦‍🔥 Pájaro de Fuego | Naranja y bordó con una franja amarilla y chispas |
| 🦋 Mariposa | Amarillo y naranja con manchas rosas y celestes, y dos mariposas |
| 🪷 Nenúfar | Verdes a rayas con una flor de loto arriba |
| 🦎 Camaleón | Todos los colores, óvalos de arcoíris y cuernos |
| 🛡️ Paladín | Blanco con cinturón y tiras doradas, corona y alas de plumas |
| 🥽 Láser | Amarillo y naranja con óvalos y un visor negro con borde rojo que brilla |
| ⚙️ Metal Caliente | Negro y gris con óvalos naranjas y lava al frente |
| 🏔️ Alpino | Roca gris abajo, nieve en el medio, cielo arriba y pinitos |
| ❄️ Copo de Nieve | Azules con un copo grande al frente y cuatro chicos |
| 🌗 Fuego Fresco | Mitad azul y mitad naranja, con una costura azul noche |
| ⚽ Fútbol | Pelota blanca con pentágonos negros y una estrellita dorada |
| 🧊 Cubo de Hielo | Celestes y transparentes, óvalos azules, puntas de cristal, sobre un cubo de hielo |
| 🍨 Helado | Rojo abajo, crema que chorrea arriba y una cereza |
| 🌼 Diente de León | Blanco y gris claro, con semillitas que vuelan |
| 🍹 Mojito | De amarillo a verde oscuro, con hojas de menta arriba |
| Puro Fuego / Pura Tierra / Puro | Collar dorado con medallón; cuernos, colmillos o nubes, sobre pie transparente |
| Espejo, Platino, Mercurio, Perla, Oro | Ladrillos que brillan como metal (y lucecitas, tuercas o gotas) |
| Viento, Zombi, Fósil, Pingüino, Neón | Remolino; cristales que cuelgan; ventana con huesos; panza blanca; franjas de neón |
| Serpiente de Cascabel, Fuego Oscuro | Víbora enroscada al frente; brazos violetas que giran |
| Vampiro, Veneno, Erizo, Oscuro | Lava con cinturón y rubí; venas y espinas verdes; púas y hocico; púas negras |
| Batería, Petróleo | Franja con rayo y tapa de metal; negro con tapa de botella |
| Libélula, Jade, Concha, Cristal | Ojos y alas transparentes; jade; conchitas pastel; cristales que salen |
| Popó, Legendario, Pirata, Planta Carnívora | Anillos marrones; arcoíris con nube y estrellas; sombrero, parche y bigote; boca con dientes y hojas |
| Robot, Steampunk, Medieval | Lente azul y luces; cúpula de cobre, engranaje y caño; casco de caballero |

## Íconos de los elementos

Roblox no lee imágenes desde la carpeta del proyecto: hay que subirlas una vez.

1. En Studio: **View → Asset Manager → Bulk Import** y elegí los PNG de `assets/elementos`.
2. Click derecho en cada imagen → **Copy Asset ID**.
3. Pegá cada id en la tabla `ICONS` de `src/shared/Elements.luau` (por ejemplo `llama = "123456789"`).

Mientras un id esté vacío, la etiqueta muestra el elemento sin ícono.

- `assets/elementos/`: los íconos propios (Alma, Guerra, Mar, Puro, Terra, Tiempo, Viento).
- `assets/elementos/provisorios/`: los que todavía son del juego original. Hay que reemplazarlos antes de publicar.
- `assets/monedas/`: oro, gema, comida y xp, para la interfaz que viene.

Los PNG salen de las imágenes de `Escritorio/Huevos` con el fondo blanco recortado.

## Cómo está hecho

| Archivo | Qué hace |
|---|---|
| `src/shared/Eggs.luau` | Todos los huevos: paleta, cómo se pinta cada ladrillo, adornos y efectos |
| `src/shared/EggBuilder.luau` | Arma la cáscara por capas, la pinta y junta las celdas iguales en ladrillos de 1 a 4 |
| `src/shared/EggDecor.luau` | Adornos: aletas, espinas, brazo de cactus, coral, estrella, hojas, cúpulas, puntos, pie, copos, pinos, cuernos, visor, corona, alas, flor de loto y mariposas |
| `src/shared/Paint.luau` | Ayudas para pintar (elegir color por peso, líneas, óvalos a los costados) |
| `src/shared/Elements.luau` | Los 21 elementos (Terra, Llama, Mar, Naturaleza...), sus colores y los ids de sus íconos |
| `assets/` | Íconos de elementos y monedas en PNG, listos para subir a Roblox |
| `src/server/Main.server.luau` | La galería (huevos en anillos) y las etiquetas arriba de cada huevo |
| `src/client/Spin.client.luau` | Hace girar los huevos cercanos |
| `src/client/Labels.client.luau` | Anima las etiquetas: letras en ola, cartel que flota y colores que giran |

**Agregar un huevo:** copiá uno de `Eggs.list` y cambiale el `id`, el `element` (uno, o dos como
`{ "llama", "hielo" }`), la paleta y la función `paint`.
`paint(c)` recibe la posición de cada ladrillo (`c.t` = altura de -1 a 1, `c.u`/`c.v` = posición
sobre el frente, `c.noise` = manchas) y devuelve el nombre de un color de la paleta. La forma del
huevo (ancho, capas, qué tan panzón) está en `EggBuilder.Shape`.

Los ladrillos no llevan ningún logo ni marca: son solo studs.
