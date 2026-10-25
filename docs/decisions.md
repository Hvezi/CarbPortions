# Decisions log

## D1 - Column selection
<sub>25 October 2026</sub>

### Context

The Open Food Facts export has 201 columns. Most of them are not useful for this project, and loading all of them makes the workbook slow and hard to read.

### Decision

Keep 34 columns.

- **Identification:** find a product and show its photo in the search sheet. *(code, product_name, brands_en, image_small_url)*
- **Category:** group products for the analysis. *(main_category_en, pnns_groups_1, pnns_groups_2)*
- **Filter:*** keep only products sold in Spain. *(countries_tags)*
- **Serving and package:** suggest a default amount in the calculator. *(serving_size, serving_quantity, product_quantity)*
- **Macros (per 100 g):** basic nutrition. carbohydrates_100g is the key column. *(energy-kcal_100g, fat_100g, saturated-fat_100g, carbohydrates_100g, proteins_100g)*
- **Diabetes (per 100 g):** show what kind of carbs a product has. *(sugars_100g, added-sugars_100g, glucose_100g, starch_100g, polyols_100g, fiber_100g, glycemic-index_100g)*
- **General health:** heart health, food quality and a gluten-free filter. *(salt_100g, cholesterol_100g, nutriscore_grade, nova_group, allergens_tags, traces_tags)*
- **Data quality:** measure how reliable each product is and sort by popularity. *(completeness, no_nutrition_data, data_quality_errors_tags, last_modified_datetime, unique_scans_n)*

### Rules

- When a column comes in two versions, `_tags` is used to filter and `_en` to display. Only one version is kept.
- Repeated data is dropped: sodium_100g (salt = sodium × 2.5) and the energy columns in kJ.

### Discarded

- **URLs and most images:** only one small photo is needed.
- **Single fatty acids (30+ columns):** too detailed; total and saturated fat are enough.
- **Vitamins and minerals:** almost always empty and not relevant for carb counting.
- **Ingredient text:** free text, hard to analyse in Excel.
- **Environmental data:** outside the scope of the project.
- **Stores:** very incomplete; countries_tags is enough to filter.
- **Who edited each product and when it was created:** not useful for the user.
