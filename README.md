# Retail Sales & Customer Intelligence Using PostgreSQL

## What the project is

Duka Smart Electronics is a Kenyan retailer selling phones, laptops, accessories, TVs and home
appliances in ten towns. This project creates its `retail_analytics` PostgreSQL database
(150 customers, 800 orders), answers 46 business questions in SQL, and writes up what
management should do.

| File | Contents |
|---|---|
| `schema.sql` | `CREATE TABLE` statements for `customers` and `orders` |
| `queries.sql` | All 46 answers, numbered `-- Q1` … `-- Q46` |
| `insights.md` | Business insights with the numbers, why they matter, and recommendations |
| `screenshots/` | `05_verify_data.sql` output and selected query results (named by question, e.g. `q33_category_profit_margin.png` is Q33) |

## How to set it up (DBeaver)

1. Create a PostgreSQL connection: host `localhost`, port `5432`, database `postgres`,
   user `postgres`.
2. Open an SQL editor and run:
   ```sql
   CREATE DATABASE retail_analytics;
   ```
3. Connect to `retail_analytics` (edit the connection's database, or tick *Show all databases*
   on the PostgreSQL tab).
4. Open each script from the project page and run it with **Alt+X** (Execute script), in order:
   `02_create_tables.sql` (or `schema.sql`), `03_insert_customers.sql`, `04_insert_orders.sql`,
   `05_verify_data.sql`.
5. `05_verify_data.sql` should show 150 customers and 800 orders.

## How to run the queries

1. Open `queries.sql` while connected to `retail_analytics`.
2. Run one query with **Ctrl+Enter** (cursor inside it), or the whole file with **Alt+X**.
3. Run Q43 before Q46 — Q46 reads from the `monthly_sales_summary` view that Q43 creates.
4. Run the Q44 `CREATE FUNCTION` statement on its own (select it, then Ctrl+Enter) so DBeaver
   does not split its `$$ … $$` body.
