#!/usr/bin/env python3
"""把 gettext .po 编译成 .mo（无需安装 gettext / msgfmt）。

Neovim 安装包不附带中文 .mo，本脚本用于在安装时把官方 zh_CN.UTF-8.po
编译成 nvim.mo。支持 msgid/msgstr 多行字符串，跳过 fuzzy 与复数条目。

用法：
    python3 scripts/po2mo.py zh_CN.UTF-8.po nvim.mo
"""
import ast
import struct
import sys


def parse_po(text: str) -> list[tuple[str, str]]:
    entries: list[tuple[str, str]] = []
    msgid = msgstr = None
    field = None
    fuzzy = False
    unsupported = False

    def flush() -> None:
        nonlocal msgid, msgstr, field, fuzzy, unsupported
        if msgid is not None and msgstr is not None and not fuzzy and not unsupported:
            entries.append((msgid, msgstr))
        msgid = msgstr = None
        field = None
        fuzzy = False
        unsupported = False

    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            flush()
            continue
        if line.startswith("#"):
            if line.startswith("#,") and "fuzzy" in line:
                fuzzy = True
            continue
        if line.startswith("msgid_plural") or line.startswith("msgstr[") or line.startswith("msgctxt"):
            unsupported = True
            continue
        if line.startswith("msgid "):
            if msgid is not None and msgstr is not None:
                flush()
            msgid = ast.literal_eval(line[6:])
            field = "id"
            continue
        if line.startswith("msgstr "):
            msgstr = ast.literal_eval(line[7:])
            field = "str"
            continue
        if line.startswith('"'):
            value = ast.literal_eval(line)
            if field == "id":
                msgid += value
            elif field == "str":
                msgstr += value
    flush()
    return entries


def write_mo(entries: list[tuple[str, str]], path: str) -> None:
    # .mo 要求按 msgid 的字节序排序，gettext 才能二分查找
    entries = sorted(entries, key=lambda kv: kv[0].encode("utf-8"))
    n = len(entries)
    orig_table_off = 28
    trans_table_off = 28 + 8 * n
    orig_blob_off = 28 + 16 * n

    orig_blob = bytearray()
    trans_blob = bytearray()
    orig_table = bytearray()
    trans_table = bytearray()

    for msgid, _ in entries:
        data = msgid.encode("utf-8")
        orig_table += struct.pack("II", len(data), orig_blob_off + len(orig_blob))
        orig_blob += data + b"\x00"

    trans_blob_off = orig_blob_off + len(orig_blob)
    for _, msgstr in entries:
        data = msgstr.encode("utf-8")
        trans_table += struct.pack("II", len(data), trans_blob_off + len(trans_blob))
        trans_blob += data + b"\x00"

    header = struct.pack(
        "IIIIIII",
        0x950412DE,  # magic
        0,  # revision
        n,  # number of strings
        orig_table_off,
        trans_table_off,
        0,  # hash table size
        0,  # hash table offset
    )
    with open(path, "wb") as f:
        f.write(header + orig_table + trans_table + orig_blob + trans_blob)


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit("用法：python3 scripts/po2mo.py INPUT.po OUTPUT.mo")
    with open(sys.argv[1], encoding="utf-8") as f:
        entries = parse_po(f.read())
    if not entries:
        sys.exit("没有解析到任何翻译条目，请检查 .po 文件是否为 UTF-8 编码")
    write_mo(entries, sys.argv[2])


if __name__ == "__main__":
    main()
