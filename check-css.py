"""Check that every block in a stylesheet is closed.

A stylesheet whose last rule is never closed still works, because a parser closes
any open blocks at the end of the file. It only bites when something is appended
later, which then silently becomes nested inside the unclosed rule and stops
matching anything. Minifiers close the blocks at the end of the file too, so they
report no error either. Only counting the braces finds it.

Usage: python check-css.py [path ...]   (defaults to static/styles.css)
"""

import sys


def strip_noise(css):
    """Blank out comments and quoted strings, keeping the line structure intact.

    Braces inside a comment or a string, such as content: '{', are not nesting and
    must not be counted.
    """
    out = []
    i = 0
    length = len(css)
    while i < length:
        two = css[i : i + 2]
        if two == "/*":
            end = css.find("*/", i + 2)
            end = length if end == -1 else end + 2
            # Keep the newlines so reported line numbers stay right.
            out.append("\n" * css.count("\n", i, end))
            i = end
        elif css[i] in "\"'":
            quote = css[i]
            j = i + 1
            while j < length and css[j] != quote:
                # A backslash escapes the next character, including a quote.
                j += 2 if css[j] == "\\" else 1
            end = min(j + 1, length)
            out.append("\n" * css.count("\n", i, end))
            i = end
        else:
            out.append(css[i])
            i += 1
    return "".join(out)


def check(path):
    with open(path) as handle:
        source = handle.read()

    lines = strip_noise(source).split("\n")
    opened = []
    for number, line in enumerate(lines, start=1):
        for character in line:
            if character == "{":
                opened.append(number)
            elif character == "}":
                if not opened:
                    print(f"{path}:{number}: a closing brace with nothing to close")
                    return False
                opened.pop()

    if opened:
        for number in opened:
            text = source.split("\n")[number - 1].strip()
            print(f"{path}:{number}: this block is never closed:  {text}")
        print(
            f"{path}: {len(opened)} unclosed block(s). "
            "Anything added at the end of the file is nested inside them, "
            "so its selectors will not match."
        )
        return False

    return True


def main():
    paths = sys.argv[1:] or ["static/styles.css"]
    ok = True
    for path in paths:
        if check(path):
            print(f"{path}: all blocks closed")
        else:
            ok = False
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
