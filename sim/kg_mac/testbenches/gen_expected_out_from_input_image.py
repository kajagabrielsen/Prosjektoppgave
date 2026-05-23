import sys
from datetime import datetime

IMG_W = 28
IMG_H = 28
K = 3
N = K * K

if len(sys.argv) != 2:
    print("Usage: python3 gen_expected_out_from_input_image.py <TRUNC_BITS>")
    sys.exit(1)

TRUNC_BITS = int(sys.argv[1])

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

expected_name = f"expected_trunc{TRUNC_BITS}_{timestamp}.txt"

def trunc(value, bits):
    return value if bits == 0 else value >> bits

# Read weights
with open("weights.txt") as f:
    weights = [int(x) for x in f.readline().split()]

# Read image
image = []
with open("input_image.txt") as f:
    for line in f:
        row = [int(x) for x in line.split()]
        if row:
            image.append(row)

# Generate expected
with open(expected_name, "w") as f:
    for out_r in range(IMG_H - K + 1):
        for out_c in range(IMG_W - K + 1):

            window = [
                image[out_r+0][out_c+0], image[out_r+0][out_c+1], image[out_r+0][out_c+2],
                image[out_r+1][out_c+0], image[out_r+1][out_c+1], image[out_r+1][out_c+2],
                image[out_r+2][out_c+0], image[out_r+2][out_c+1], image[out_r+2][out_c+2],
            ]

            acc = sum(x*w for x, w in zip(window, weights))
            f.write(f"{trunc(acc, TRUNC_BITS)}\n")

print("Generated:")
print(" ", expected_name)
print("TRUNC_BITS =", TRUNC_BITS)