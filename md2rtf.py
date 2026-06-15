#!/usr/bin/env python3
r"""
md2rtf.py - convert whatsnew.md into whatsnew.rtf, matching the styling the
existing whatsnew.rtf uses (Segoe UI; headings bold + underlined with
decreasing sizes; bullet / en-dash lists; 12pt body).

Usage:
    python md2rtf.py whatsnew.md whatsnew.rtf [--stop-before "# What's new in xEdit 4.0.5?"]

Style map (half-point sizes; RTF \fs is half-points):
    # heading   -> 18pt  (\fs36)  bold + underline
    ## heading  -> 16pt  (\fs32)  bold + underline
    ### heading -> 14pt  (\fs28)  bold + underline
    #### heading-> 13pt  (\fs26)  bold + underline   (deeper levels clamp to 13pt)
    body text   -> 12pt  (\fs24)
    * item      -> bullet (\bullet) + tab, hanging indent
    - item (>=2 space indent) -> en-dash (\endash) + tab, deeper indent
    `code`      -> rendered as plain body text (no monospace), matching the source rtf
    **bold**    -> bold run
"""
import re
import sys

FONT = r'\f0'          # Segoe UI (defined in the font table below)
HEADING_FS = {1: 36, 2: 32, 3: 28, 4: 26, 5: 26, 6: 26}
HEADING_SB = {1: 360, 2: 300, 3: 240, 4: 200, 5: 200, 6: 200}  # space-before (twips); 20ths of a point
BODY_FS = 24
UL = r'\ulth'          # thick underline, matching the existing whatsnew.rtf

TOKEN = re.compile(r'(\*\*.+?\*\*|`[^`]+`)')


def esc(s):
    """Escape text for RTF; non-ASCII -> \\uN? ; strip BOM."""
    out = []
    for ch in s:
        if ch == '﻿':
            continue
        if ch == '\\':
            out.append('\\\\')
        elif ch == '{':
            out.append('\\{')
        elif ch == '}':
            out.append('\\}')
        else:
            c = ord(ch)
            if c < 128:
                out.append(ch)
            else:
                n = c if c <= 32767 else c - 65536
                out.append('\\u%d?' % n)
    return ''.join(out)


def inline(s):
    """Process inline markdown: **bold** and `code` (-> plain).
    No link handling: this document never uses [] as link markers, so all
    square brackets ([TES4], [FE 001], [Assets Manager], ...) stay literal."""
    out = []
    for part in TOKEN.split(s):
        if not part:
            continue
        if part.startswith('**') and part.endswith('**'):
            out.append(r'{\b ' + esc(part[2:-2]) + '}')
        elif part.startswith('`') and part.endswith('`'):
            out.append(esc(part[1:-1]))               # code -> plain text
        else:
            out.append(esc(part))
    return ''.join(out)


def convert(md_text, stop_before=None):
    md_text = md_text.replace('﻿', '')   # strip BOM/zero-width so a leading "# " heading is recognized
    lines = md_text.replace('\r\n', '\n').replace('\r', '\n').split('\n')
    body = []
    in_fence = False
    for raw in lines:
        line = raw
        stripped = line.strip()

        if stop_before is not None and stripped == stop_before:
            break

        if stripped.startswith('```'):           # skip fenced code fences
            in_fence = not in_fence
            continue
        if in_fence:
            body.append(r'\pard\sa180{%s\fs%d %s}\par' % (FONT, BODY_FS, inline(stripped)))
            continue
        if not stripped:                          # blank line: spacing via \sa
            continue

        m = re.match(r'^(#{1,6})\s+(.*)$', stripped)
        if m:
            level = len(m.group(1))
            fs = HEADING_FS[level]
            body.append(r'\pard\sb%d\sa180{\b%s\fs%d%s %s}\par'
                        % (HEADING_SB[level], FONT, fs, UL, inline(m.group(2))))
            continue

        om = re.match(r'^(\s*)\d+\.\s+(.*)$', line)
        if om:
            indent = len(om.group(1))
            li = 720 if indent >= 2 else 360
            num = re.match(r'^\s*(\d+)\.', line).group(1)
            body.append(r'\pard\fi-360\li%d\tx%d{%s\fs%d %s.\tab %s}\par'
                        % (li, li, FONT, BODY_FS, num, inline(om.group(2))))
            continue

        bm = re.match(r'^(\s*)[*\-]\s+(.*)$', line)
        if bm:
            indent = len(bm.group(1))
            if indent >= 2:
                body.append(r'\pard\fi-360\li720\tx720{%s\fs%d \endash\tab %s}\par'
                            % (FONT, BODY_FS, inline(bm.group(2))))
            else:
                body.append(r'\pard\fi-360\li360\tx360{%s\fs%d \bullet\tab %s}\par'
                            % (FONT, BODY_FS, inline(bm.group(2))))
            continue

        body.append(r'\pard\sa180{%s\fs%d %s}\par' % (FONT, BODY_FS, inline(stripped)))

    preamble = (r'{\rtf1\ansi\ansicpg1252\deff0'
                r'{\fonttbl{\f0\fswiss\fcharset0 Segoe UI;}}'
                '\r\n')
    return preamble + '\r\n'.join(body) + '\r\n}\r\n'


def main():
    args = sys.argv[1:]
    stop_before = None
    if '--stop-before' in args:
        i = args.index('--stop-before')
        stop_before = args[i + 1]
        del args[i:i + 2]
    if len(args) != 2:
        sys.exit('usage: python md2rtf.py input.md output.rtf [--stop-before "<line>"]')
    md = open(args[0], encoding='utf-8').read()
    rtf = convert(md, stop_before=stop_before)
    open(args[1], 'wb').write(rtf.encode('latin-1'))
    print('wrote %s (%d bytes)' % (args[1], len(rtf)))


if __name__ == '__main__':
    main()
