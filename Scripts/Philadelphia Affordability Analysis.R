# Philly ZIP affordability vs commute

# install.packages(c("DBI","duckdb","readr","dplyr","ggplot2","viridis"))

library(DBI)
library(duckdb)
library(readr)
library(dplyr)
library(ggplot2)

con <- dbConnect(duckdb(), dbdir = ":memory:")

master <- readr::read_csv("Sample Project.csv", show_col_types = FALSE)

dbWriteTable(con, "philly", master, overwrite = TRUE)

dbGetQuery(con, "SELECT * FROM philly LIMIT 5;")

dbGetQuery(con, "
SELECT
  typeof(\"RENT BURDEN\") AS rent_burden_type,
  typeof(\"AVG_COMMUTE\") AS avg_commute_type
FROM philly
LIMIT 1;
")

dbGetQuery(con, "
SELECT DISTINCT \"MEDIAN INCOME\"
FROM philly
ORDER BY 1
LIMIT 20;
")

dbExecute(con, "
CREATE TABLE philly_clean AS
SELECT
  \"ZIP\" AS zip,
  TRY_CAST(\"MEDIAN RENT\" AS DOUBLE) AS median_rent,
  TRY_CAST(\"MEDIAN INCOME\" AS DOUBLE) AS median_income,
  TRY_CAST(\"POPULATION\" AS DOUBLE) AS population,
  TRY_CAST(\"AVG_COMMUTE\" AS DOUBLE) AS avg_commute,
  TRY_CAST(\"COMMUTE_30+\" AS DOUBLE) AS commute_30_plus,
  TRY_CAST(REPLACE(\"RENT BURDEN\", '%', '') AS DOUBLE) AS rent_burden
FROM philly;
")

dbGetQuery(con, "SELECT * FROM philly_clean LIMIT 5;")

dbExecute(con, "
CREATE OR REPLACE VIEW philly_model AS
SELECT *
FROM philly_clean
WHERE rent_burden IS NOT NULL
  AND avg_commute IS NOT NULL
  AND population IS NOT NULL;
")

dbExecute(con, "
CREATE OR REPLACE VIEW philly_scored AS
WITH mm AS (
  SELECT
    MIN(rent_burden) AS min_rb, MAX(rent_burden) AS max_rb,
    MIN(avg_commute) AS min_ac, MAX(avg_commute) AS max_ac
  FROM philly_model
)
SELECT
  p.*,
  ROUND(100 * (
    0.5 * (1 - (rent_burden - min_rb) / NULLIF(max_rb - min_rb, 0)) +
    0.5 * (1 - (avg_commute - min_ac) / NULLIF(max_ac - min_ac, 0))
  ), 1) AS score_0_100
FROM philly_model p, mm;
")

dbGetQuery(con, "
SELECT zip, rent_burden, avg_commute, score_0_100
FROM philly_scored
ORDER BY score_0_100 DESC
LIMIT 10;
")

philly_df <- dbGetQuery(con, "SELECT * FROM philly_scored;") %>%
  mutate(
    livable = rent_burden < 30 & avg_commute < 35,
    quadrant = case_when(
      rent_burden < 30 & avg_commute < 35 ~ "Low burden / Short commute",
      rent_burden < 30 & avg_commute >= 35 ~ "Low burden / Long commute",
      rent_burden >= 30 & avg_commute < 35 ~ "High burden / Short commute",
      TRUE ~ "High burden / Long commute"
    )
  )

philly_df %>% count(quadrant, sort = TRUE)
mean(philly_df$livable) * 100
sum(philly_df$livable)

p <- ggplot(philly_df, aes(x = avg_commute, y = rent_burden)) +
  geom_point(aes(size = population, color = livable), alpha = 0.65) +
  geom_vline(xintercept = 35, linetype = "dashed") +
  geom_hline(yintercept = 30, linetype = "dashed") +
  labs(
    title = "Philadelphia Housing Affordability vs. Commute by ZIP Code",
    x = "Average Commute Time (minutes)",
    y = "Rent Burden (% of Income)",
    size = "Population",
    color = "Meets Livability Threshold"
  ) +
  theme_minimal()

p
ggsave("philly_affordability_commute.png", plot = p, width = 8, height = 6, dpi = 300, bg = "white")

top10 <- philly_df %>%
  arrange(desc(score_0_100)) %>%
  slice_head(n = 10)

bar_plot <- ggplot(top10, aes(x = reorder(zip, score_0_100), y = score_0_100)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Top 10 Philadelphia ZIP Codes by Affordability–Commute Balance",
    x = "ZIP Code",
    y = "Affordability–Commute Score (0–100)"
  ) +
  theme_minimal()
bar_plot

ggsave(
  "top10_affordability_commute.png",
  plot = bar_plot,
  width = 8,
  height = 6,
  dpi = 300,
  bg = "white"
)
