import pandas as pd
import sqlite3
import glob

files = sorted(glob.glob("data/*.csv"))
df = pd.concat([pd.read_csv(f, low_memory=False) for f in files], ignore_index=True)
df = df.loc[:, ~df.columns.str.startswith("Unnamed")]

# Parse dates and add a clean month column
df["FL_DATE"] = pd.to_datetime(df["FL_DATE"], format="%m/%d/%y %H:%M")
df["MONTH"] = df["FL_DATE"].dt.month

conn = sqlite3.connect("flights.db")
df.to_sql("flights", conn, if_exists="replace", index=False)
conn.close()

print("Rows loaded:", len(df))
