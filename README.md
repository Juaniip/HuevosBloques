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

## Monedas

Cinco botones en el piso, delante de donde aparecés: pisás uno y recolectás una cantidad al azar de
**gemas**, **oro**, **comida**, **XP** o **estrellas**. Sale un "+99" con el ícono y arriba al centro
está la barra con gemas, oro y comida (el número sube contando). XP y estrellas se guardan igual,
pero no van en la barra (`bar = false`).

- Cantidades y tiempo de espera de cada botón: `src/shared/Currencies.luau` (`pad = { min, max, cooldown }`).
- Íconos: son las imágenes de `assets/monedas` (las de `Escritorio/Huevos/Monedas` sin el fondo).
  Subilas una vez y pegá cada número en `icon` de `Currencies.luau`.
- Lo guardado se carga con Kit.DataStore. En Studio hace falta **Game Settings → Security → Enable
  Studio Access to API Services** para que quede guardado entre partidas.
- El botón verde "+" todavía no abre nada: avisa por `CurrencyHud.plusClicked` (para la tienda).

## Íconos de los elementos

Roblox no lee imágenes desde la carpeta del proyecto: hay que subirlas una vez.

1. En Studio: **Ventana → Administrador de recursos → Importación masiva** y elegí los PNG de `assets/elementos`.
2. Click derecho en cada imagen → **Copy Asset ID**.
3. Pegá cada id en la tabla `ICONS` de `src/shared/Elements.luau` (por ejemplo `llama = "123456789"`).

Mientras un id esté vacío, la etiqueta muestra el elemento sin ícono.

- `assets/elementos/`: las 21 banderas de elementos.
- `assets/monedas/`: oro, gema, comida y xp.

Los PNG salen de las imágenes de `Escritorio/Huevos/Elementos` y `/Monedas` con el fondo blanco
recortado. Si cambiás o agregás alguna, volvé a generarlos con:

```bash
python tools/recortar.py
```

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
| `src/shared/Currencies.luau` | Las monedas, cuánto da cada botón y el formato "1.68 M" |
| `src/server/Wallet.luau` | Billetera de cada jugador (guardado y atributos) |
| `src/server/Pads.luau` | Botones del piso: detectan la pisada y dan la moneda |
| `src/client/CurrencyHud.luau` | Barra de monedas de arriba |
| `src/client/CollectPopup.luau` | El "+99" que sale del botón y los íconos que flotan sobre los botones |
| `src/client/CurrencyIcon.luau` | Ícono de cada moneda (imagen subida o dibujo simple) |

**Agregar un huevo:** copiá uno de `Eggs.list` y cambiale el `id`, el `element` (uno, o dos como
`{ "llama", "hielo" }`), la paleta y la función `paint`.
`paint(c)` recibe la posición de cada ladrillo (`c.t` = altura de -1 a 1, `c.u`/`c.v` = posición
sobre el frente, `c.noise` = manchas) y devuelve el nombre de un color de la paleta. La forma del
huevo (ancho, capas, qué tan panzón) está en `EggBuilder.Shape`.

Los ladrillos no llevan ningún logo ni marca: son solo studs.
