"""Validate the isolated Harlequin runtime without contacting a database."""

import sys
from importlib.metadata import entry_points, version


def main():
    if sys.version_info[:2] != (3, 14):
        raise RuntimeError(f"Harlequin requires Python 3.14; found {sys.version.split()[0]}")

    adapters = {entry.name: entry for entry in entry_points(group="harlequin.adapter")}
    for name in ("postgres", "mysql"):
        if name not in adapters:
            raise RuntimeError(f"Missing Harlequin adapter: {name}")
        adapters[name].load()

    import duckdb
    import mysql.connector
    import psycopg

    # Exercise the native database engine used for Harlequin's result tables.
    with duckdb.connect(":memory:") as connection:
        if connection.execute("SELECT 42").fetchone() != (42,):
            raise RuntimeError("Harlequin's DuckDB runtime did not return the expected result")

    print(
        f"Harlequin {version('harlequin')}: Python {sys.version.split()[0]}, "
        f"PostgreSQL driver {psycopg.__version__}, MySQL driver {mysql.connector.__version__}"
    )


if __name__ == "__main__":
    main()
