"""Pasa las imágenes diseñadas (Escritorio/Huevos/Elementos y /Monedas) a PNG con fondo transparente.

Saca el fondo blanco que toca los bordes (lo blanco de adentro del dibujo se queda), recorta lo que
sobra y deja la imagen de 512 px como máximo en assets/elementos y assets/monedas.

    python tools/recortar.py
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

HUEVOS = os.path.join(os.path.expanduser("~"), "Desktop", "Huevos")
ASSETS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")

# Palabra que aparece en el nombre del archivo -> nombre del PNG (igual que el id en el código).
ELEMENTOS = {
    "alma": "alma", "belleza": "belleza", "caos": "caos", "electrico": "electrico", "feliz": "feliz",
    "fuego": "llama", "guerra": "guerra", "hielo": "hielo", "leyenda": "leyenda", "luz": "luz",
    "magico": "magia", "mar": "mar", "metal": "metal", "naturaleza": "naturaleza", "oscuro": "oscuro",
    "primal": "primitivo", "puro": "puro", "sueño": "sueno", "terra": "terra", "tiempo": "tiempo",
    "viento": "viento",
}
MONEDAS = {"food": "comida", "gema": "gema", "oro": "oro", "star": "estrella", "xp": "xp"}


def recortar(origen, destino, size=512):
    im = Image.open(origen).convert("RGB")
    a = np.asarray(im).astype(np.int16)
    mn, mx = a.min(axis=2), a.max(axis=2)
    white = (mn > 228) & (mx - mn < 25)
    # .copy(): la imagen que sale de numpy es de solo lectura y el relleno no se guardaría.
    mask = Image.fromarray(np.where(white, 255, 0).astype(np.uint8), "L").copy()
    w, h = mask.size
    bordes = [(x, 0) for x in range(w)] + [(x, h - 1) for x in range(w)]
    bordes += [(0, y) for y in range(h)] + [(w - 1, y) for y in range(h)]
    for xy in bordes:
        if mask.getpixel(xy) == 255:
            ImageDraw.floodfill(mask, xy, 128, thresh=0)
    fondo = np.asarray(mask) == 128
    alpha = np.where(fondo, 0, 255).astype(np.uint8)
    # Contorno suave: lo casi blanco pegado al fondo queda semitransparente.
    borde = np.zeros_like(fondo)
    borde[1:, :] |= fondo[:-1, :]
    borde[:-1, :] |= fondo[1:, :]
    borde[:, 1:] |= fondo[:, :-1]
    borde[:, :-1] |= fondo[:, 1:]
    suave = borde & ~fondo & (mn > 200)
    alpha[suave] = np.clip((255 - mn[suave]) * 5, 80, 255)
    img = Image.fromarray(np.dstack([np.asarray(im), alpha]), "RGBA")
    img = img.crop(img.getbbox())
    img.thumbnail((size, size), Image.LANCZOS)
    img.save(destino)


def procesar(carpeta, nombres, salida):
    os.makedirs(salida, exist_ok=True)
    hechos = set()
    for archivo in sorted(os.listdir(carpeta)):
        base, ext = os.path.splitext(archivo)
        if ext.lower() not in (".jpg", ".jpeg", ".png", ".webp"):
            continue
        clave = base.lower().replace("elemento", "").strip()
        if clave not in nombres:
            print(f"  ? no sé qué es '{archivo}' (agregalo a la lista del script)")
            continue
        recortar(os.path.join(carpeta, archivo), os.path.join(salida, nombres[clave] + ".png"))
        hechos.add(nombres[clave])
        print(f"  {archivo} -> {nombres[clave]}.png")
    faltan = sorted(set(nombres.values()) - hechos)
    if faltan:
        print("  Faltan:", ", ".join(faltan))


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    print("Elementos:")
    procesar(os.path.join(HUEVOS, "Elementos"), ELEMENTOS, os.path.join(ASSETS, "elementos"))
    print("Monedas:")
    procesar(os.path.join(HUEVOS, "Monedas"), MONEDAS, os.path.join(ASSETS, "monedas"))
