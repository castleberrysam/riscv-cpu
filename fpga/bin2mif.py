#!/usr/bin/env python3

import sys
from struct import unpack

def main():
    if len(sys.argv) < 3:
        print("Usage: " + sys.argv[0] + " <bin file> <length>")
        exit(1)

    outlen = int(sys.argv[2])
    with open(sys.argv[1], "rb") as f:
        while outlen > 0:
            word = f.read(4)
            if len(word) < 4:
                break
            word = unpack("<I", word)[0]
            print("{:032b}".format(word))
            outlen -= 1

    while outlen > 0:
        print("{:032b}".format(0))
        outlen -= 1

if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        pass
