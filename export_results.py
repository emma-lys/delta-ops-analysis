import sqlite3
import pandas as pd
import os

os.makedirs("results", exist_ok=True)
conn = sqlite3.connect("flights.db")

with open("queries.sql") as f:
    queries = [q for q in f.read().split(";") if "SELECT" in q]

names = ["q1_airlines", "q2_hubs", "q3_delay_causes", "q4_atl_by_hour", "q5_cancellations"]
assert len(queries) == len(names), f"Expected {len(names)} queries, found {len(queries)}"

for name, q in zip(names, queries):
    pd.read_sql(q, conn).to_csv(f"results/{name}.csv", index=False)
    print("Saved", name)

conn.close()
