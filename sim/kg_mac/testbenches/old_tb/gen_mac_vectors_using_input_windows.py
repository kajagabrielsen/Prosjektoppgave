import random
import sys
from datetime import datetime

# ----------------------------
# Read TRUNC_BITS from command line
# ----------------------------
if len(sys.argv) != 2:
    print("Usage: python gen_mac_vectors_using_input_windows.py <TRUNC_BITS>")
    sys.exit(1)

TRUNC_BITS = int(sys.argv[1])

# ----------------------------
# Configuration
# ----------------------------
K = 3
N = K * K
X_W_WIDTH = 8
N_TESTS = 1000

random.seed(1)

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

input_name = f"input_trunc{TRUNC_BITS}_{timestamp}.txt"
output_name = f"expected_trunc{TRUNC_BITS}_{timestamp}.txt"

# ----------------------------
# Golden MAC
# ----------------------------
def mac_expected(x, w, trunc_bits):
    acc = 0
    for xi, wi in zip(x, w):
        prod = xi * wi
        prod_t = prod >> trunc_bits  # arithmetic shift
        acc += prod_t
    return acc

# ----------------------------
# Generate files
# ----------------------------
w = [random.randint(-128, 127) for _ in range(N)]  # weights ONCE

with open(input_name, "w") as fin, open(output_name, "w") as fout:
    for _ in range(N_TESTS):
        x = [random.randint(-128, 127) for _ in range(N)]
        y = mac_expected(x, w, TRUNC_BITS)

        fin.write(" ".join(map(str, x)) + " ")
        fin.write(" ".join(map(str, w)) + "\n")

        fout.write(str(y) + "\n")

print("Generated:")
print(" ", input_name)
print(" ", output_name)
print("TRUNC_BITS =", TRUNC_BITS)