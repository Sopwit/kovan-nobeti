#!/usr/bin/env python3
"""Cuts the dark rounded tile out from behind every icon of a sheet (5 x 4 cells) so the icons can
sit on badges drawn in code.
usage: python3 tools/ikon_kes.py <in.png> <out.png>
Per cell: the tile colour is the most common opaque colour, everything connected to the cell border
that is transparent already or close to that colour goes, and the edge is feathered by colour
distance. Holes the flood cannot reach (the middle of a ring) are keyed with a tighter threshold.
Run it on the original sheet only: on a sheet that is already cut it would take an icon's dark
outline for the tile."""
import sys
import numpy as np
from PIL import Image

LO, HI = 16.0, 60.0   # colour distance: fully tile below LO, fully icon above HI

def grow(mask, cand):
    while True:
        g = mask.copy()
        g[1:] |= mask[:-1]; g[:-1] |= mask[1:]
        g[:, 1:] |= mask[:, :-1]; g[:, :-1] |= mask[:, 1:]
        g &= cand
        if (g == mask).all():
            return mask
        mask = g

def cut_cell(cell):
    rgb, a0 = cell[..., :3], cell[..., 3] / 255.0
    h, w = a0.shape
    solid = a0 > 0.8
    dark = solid & (rgb.max(axis=2) < 90)          # the tile is always dark; icons rarely are
    if not dark.any():
        return rgb, a0   # an empty cell, or one with no tile left: nothing to cut
    q = (rgb[dark] // 10).astype(np.int64)
    keys = q[:, 0] * 10000 + q[:, 1] * 100 + q[:, 2]
    vals, counts = np.unique(keys, return_counts=True)
    bg = rgb[dark][keys == vals[counts.argmax()]].mean(axis=0)
    d = np.sqrt(((rgb - bg) ** 2).sum(axis=2))
    cand = (d < HI) | (a0 < 0.5)
    seed = np.zeros((h, w), bool)
    seed[0], seed[-1], seed[:, 0], seed[:, -1] = True, True, True, True
    mask = grow(seed & cand, cand)
    ramp = np.clip((d - LO) / (HI - LO), 0.0, 1.0)
    alpha = a0.copy()
    alpha[mask] = np.minimum(alpha[mask], ramp[mask])
    inner = np.clip((d - 10.0) / 14.0, 0.0, 1.0)
    alpha[~mask] = np.minimum(alpha[~mask], inner[~mask])
    # take the tile's share back out of the half transparent pixels
    a = np.maximum(alpha, 0.05)[..., None]
    out = np.where((alpha[..., None] < 1.0) & (a0[..., None] > 0.5), np.clip((rgb - (1.0 - a) * bg) / a, 0, 255), rgb)
    return out, alpha

def main():
    px = np.asarray(Image.open(sys.argv[1]).convert("RGBA")).astype(np.float64)
    h, w = px.shape[:2]
    res = np.zeros_like(px)
    ch, cw = h // 4, w // 5
    for r in range(4):
        for c in range(5):
            y0, x0 = r * ch, c * cw
            rgb, alpha = cut_cell(px[y0:y0 + ch, x0:x0 + cw])
            res[y0:y0 + ch, x0:x0 + cw, :3] = rgb
            res[y0:y0 + ch, x0:x0 + cw, 3] = alpha * 255.0
    Image.fromarray(res.astype(np.uint8), "RGBA").save(sys.argv[2])

main()
