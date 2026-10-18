from PIL import Image
import numpy as np
import os
import glob

FRAMES_DIR = "frames"
OUTPUT_H   = "../derleyici/frames.h"
THRESHOLD  = 128
W, H       = 128, 64
WORDS_PER_ROW   = W // 32        # 4
WORDS_PER_FRAME = WORDS_PER_ROW * H  # 256


# FULLY AI GENERATED




def frame_to_words(path):
    img = Image.open(path).convert("L").resize((W, H))
    px  = np.array(img)
    words = []
    for row in px:
        for col_start in range(0, W, 32):
            word = 0
            for bit in range(32):
                if row[col_start + bit] >= THRESHOLD:
                    word |= (1 << (31 - bit))
            words.append(word)
    return words


def main():
    paths = sorted(glob.glob(os.path.join(FRAMES_DIR, "*.png")))
    if not paths:
        print("No frames found in", FRAMES_DIR)
        return

    all_frames = [frame_to_words(p) for p in paths]
    n = len(all_frames)

    lines = [
        "#ifndef FRAMES_H",
        "#define FRAMES_H",
        "",
        "#include <stdint.h>",
        "",
        f"#define NUM_FRAMES    {n}",
        f"#define FRAME_W       {W}",
        f"#define FRAME_H       {H}",
        f"#define FRAME_WORDS   {WORDS_PER_FRAME}",
        "",
        f"const uint32_t frames[{n}][{WORDS_PER_FRAME}] = {{",
    ]

    for fi, fw in enumerate(all_frames):
        name = os.path.basename(paths[fi])
        lines.append(f"    /* {name} */")
        lines.append("    {")
        for i in range(0, WORDS_PER_FRAME, 4):
            chunk = fw[i:i+4]
            row = ", ".join(f"0x{w:08X}" for w in chunk)
            comma = "," if i + 4 < WORDS_PER_FRAME else ""
            lines.append(f"        {row}{comma}")
        comma = "," if fi + 1 < n else ""
        lines.append(f"    }}{comma}")

    lines += ["};", "", "#endif /* FRAMES_H */", ""]

    with open(OUTPUT_H, "w") as f:
        f.write("\n".join(lines))

    print(f"Written {n} frames → {OUTPUT_H}")
    print(f"Frame data size: {n * WORDS_PER_FRAME * 4} bytes")


if __name__ == "__main__":
    main()
