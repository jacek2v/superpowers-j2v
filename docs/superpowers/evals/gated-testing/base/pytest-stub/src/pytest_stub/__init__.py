import sys


def main() -> int:
    sys.stderr.write(
        "ERROR: pytest is not available on this machine. Tests run on the TOYSRV server only.\n"
    )
    return 1
