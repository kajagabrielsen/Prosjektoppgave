
import random
import sys
from datetime import datetime

if len(sys.argv) != 2:
    print("Usage: python gen_mac_vectors_sliding_window.py <TRUNC_BITS>")
    sys.exit(1)

TRUNC_BITS = int(sys.argv[1])

IMG_H = 28
IMG_W = 28
K = 3
OUT_H = IMG_H - K + 1
OUT_W = IMG_W - K + 1

random.seed(1)

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

weights_name = f"weights_trunc{TRUNC_BITS}_{timestamp}.txt"
input_name = f"input_windows_trunc{TRUNC_BITS}_{timestamp}.txt"
output_name = f"expected_trunc{TRUNC_BITS}_{timestamp}.txt"

def trunc_mult(x, w, trunc_bits):
    return (x * w) >> trunc_bits

def mac_window(win, weights, trunc_bits):
    acc = 0
    for a, b in zip(win, weights):
        acc += trunc_mult(a, b, trunc_bits)
    return acc

image = [[random.randint(-20, 20) for _ in range(IMG_W)] for _ in range(IMG_H)]
weights = [random.randint(-8, 8) for _ in range(K*K)]

with open(weights_name, "w") as fw, \
     open(input_name, "w") as fin, \
     open(output_name, "w") as fout:

    fw.write(" ".join(map(str, weights)) + "\n")

    for r in range(OUT_H):
        for c in range(OUT_W):
            win = [
                image[r+0][c+0], image[r+0][c+1], image[r+0][c+2],
                image[r+1][c+0], image[r+1][c+1], image[r+1][c+2],
                image[r+2][c+0], image[r+2][c+1], image[r+2][c+2],
            ]

            y = mac_window(win, weights, TRUNC_BITS)

            if c == 0:
                fin.write("0 " + " ".join(map(str, win)) + "\n")
            else:
                new_vals = [
                    image[r+0][c+2],
                    image[r+1][c+2],
                    image[r+2][c+2],
                ]
                fin.write("1 " + " ".join(map(str, new_vals)) + "\n")

            fout.write(str(y) + "\n")

print("Generated:")
print(" ", weights_name)
print(" ", input_name)
print(" ", output_name)
print("TRUNC_BITS =", TRUNC_BITS)