# Decisions

The thinking behind the workbook: what I chose at each step and what I left out. How each sheet works is in [workbook_structure.md](workbook_structure.md), and the formulas are in [workbook_formulas.md](workbook_formulas.md).

<br>

## 25 October 2026

### Column selection

The Open Food Facts export has 201 columns. I kept 34: the ones that help find a product, count its carbs or tell how reliable its data is. When a column came in two versions, I kept one. Repeated data was dropped too, like sodium, which is just salt divided by 2.5.

**Left out:** vitamins and minerals (almost always empty), more than 30 single fatty acids, ingredient text, environmental data and stores.

### What counts as a product

The first 15,900 rows of the file are broken records, with empty barcodes or fake codes like 0. A product is kept only if it has a valid barcode, is sold in Spain, and has a name and carbs. The barcode is the only way to tell apart two products with the same name. The other columns can be empty, because asking for all of them would remove almost every product.

<br>

## 28 October 2026

### Almost empty columns

Columns with data in less than 10% of the products were dropped: glycemic index, glucose, starch and cholesterol.

Four stayed even though they are almost empty. Allergens and traces are safety information. Polyols are useful to understand "sugar free" products. And in the Open Food Facts error list, an empty cell means "no errors found", so being empty is the normal case.

### Cleaning and data types

Barcodes are stored as text, so they keep their leading zeros. As a number, 00000142 would become 142, and that barcode doesn't exist.

The file writes decimals with a point (18.1). A Spanish Excel uses the comma for decimals and the point for thousands, so it would read 18.1 as 181. That's why the numbers are read in US format. Nutrients are rounded to 2 decimals, and the text "unknown" becomes a real empty cell.

<br>

## 29 October 2026

### Text and impossible values

Names and brands are typed by thousands of people, with all caps, double spaces and several brands in one cell. Names in all caps or all lowercase get a capital first letter, so "LECHE ENTERA" becomes "Leche entera". Only the first brand is kept.

26 products with carbs below 0g or above 100g per 100g were removed, because the calculator depends on that number. Products whose numbers don't make sense, like more sugar than carbs, get flagged in a new column, *nutrition_check*. They are flagged, not deleted.

Data like this is never clean on the first try. New checks were added later, as new problems showed up.

<br>

## 30 October 2026

### Search order

The Search sheet shows one page of results at a time, so the order decides what the user sees first. Four rules sort the results. If two products tie on one rule, the next rule decides:

1. Reliable data first.
2. Products with the search word in their name, before the ones that only match by brand.
3. The most scanned products.
4. The products with the most data filled in.

The second rule exists because of one search. "galleta" showed almost only Gullón products, because their brand is "Galletas Gullón", even when "galleta" wasn't in the name.

<br>

## 31 October 2026

### How the Search sheet finds products

A product shows up when every word typed is in its name or its brand, in any order. "galleta gullon" and "gullon galleta" give the same results. People often remember the brand but not the exact name.

A barcode only works complete. With part of a code, "8410" would bring thousands of products.

### What each result shows

Of all the columns of the product table, the Search sheet shows 13: photo, barcode, name, brand, package, carbs, portions, sugars, fat, protein, kcal, data check and a link to the product page. Carbs come first, and portions are carbs divided by 10.

Empty values show "–", because "0g of sugar" is not the same as "we don't know". Flagged products stay in the results, at the end. Someone searching for their own barcode shouldn't get "No results".

### Results in pages

"galleta" returns 2,661 products. Showing all of them took more than 4 minutes, because every photo is downloaded from the internet. Pages of 20, 50 or 100 products take a few seconds.

<br>

## 1 November 2026

### Kcal check

A pack of biscuits said 3,305 kcal per 100g and passed as OK. Two new checks:

- **More than 900 kcal per 100g is impossible.** Pure fat, the most energy-dense food, has about 900.
- **The kcal must match the nutrients.** Every gram of carbs or protein gives 4 kcal and every gram of fat gives 9, so the kcal of a product can be calculated. If the label is more than 50% away from that number, the product is flagged.

The most common error is energy written in kJ instead of kcal, which makes the number about 4 times too big. The kcal are not corrected, because there's no way to know if the wrong number is the kcal or the nutrients. Flagged products went from 275 to 11,012 (4.5%).

### Capital first letter

Some names started in lowercase, like "galleta Deco". Now every name starts with a capital letter, and the rest of the name doesn't change.

### Search without accents

Excel's search doesn't ignore accents, so "maria" didn't find "Galletas María". Power Query now adds a copy of every name and brand in lowercase and without accents, only for searching. "maria", "María" and "MARIA" find the same products.

It's done in Power Query because there it runs once, when the data is loaded. In a formula it would run again on every search.

<br>

## 2 November 2026

### Three reliability levels

Open Food Facts runs its own automatic checks on every product, and the file has a column with the errors it finds, like "energy doesn't match the nutrients". Together with *nutrition_check*, that gives three levels:

- **✓** the numbers add up and Open Food Facts finds nothing wrong (93.5% of products).
- **Minor issue:** the numbers add up, but Open Food Facts found something small (2.0%).
- **&#9888;&#xFE0E; Check label:** the numbers don't add up, so the user should look at the real label (4.5%).

Errors about categories don't count, because they don't change the carbs.

<br>

## 3 November 2026

### Meal calculator

Search gives carbs per 100g, but what matters is the carbs of what you actually eat. In the Calculator, the user pastes the barcode of each food and types how much they eat. Each food is worked out in two steps:

- **Carbs:** the carbs the label gives for 100g, times the grams you eat, divided by 100.
- **Portions:** those carbs divided by 10.

For example, a bread with 50g of carbs per 100g, and you eat 60g: 50 × 60 ÷ 100 = 30g of carbs, and 30 ÷ 10 = 3 portions.

The calculator uses the barcode and not the name, because 8 different products are called "Paleta de Teruel". The portions of the meal come from the total carbs, not from adding up rounded numbers.

Later it got the look of a real calculator, with a screen for the totals and two keys: C clears the meal and ← removes the last food.

It stops at portions on purpose, because insulin doses depend on each person.

<br>

## 4 November 2026

### Search speed

Excel froze during a big search and I lost unsaved work. The cause: the search checks all 246,846 products, and that check was running about 8 times per search, because every formula that needed the result calculated it again from scratch.

Three changes fixed it. The number of matches is stored once in a hidden cell, so the other formulas read it instead of searching again. The words are counted for all products in one operation (MMULT), instead of product by product (BYROW). And the rule "word in the name first" only runs on the products that already match. Searches with 5,000 matches, like "leche", now work without freezing.

<br>

## 6 November 2026

### Data model for the dashboard

The dashboard groups products in carb intervals (0-10g, 10-20g…), and that column doesn't exist in the data. A normal pivot table can group them, but then any calculation on top, like the share of sugar of each interval, returns 0. Formulas next to the pivot table work, but the filters don't change them.

So the dashboard runs on the data model (Power Pivot). The intervals and calculations are written in DAX inside the model, and the pivot tables and filters work with them. Power Query keeps what is true about a product in any case, and the model keeps what only this analysis needs. Changing a chart never touches the clean data.

The dashboard only counts validated products, the ones whose numbers add up. The most scanned list only has products sold only in Spain. Scans are counted in every country, and without that filter the top was French.

<br>

## 7 November 2026

### Supermarket brands

The file says where a product is sold, but not who owns the brand. A Coca-Cola sold in Mercadona is not a Mercadona brand. So I made a list of 51 own brands of the Spanish supermarket chains, like Hacendado (Mercadona) or Deliplus, and every product goes into one group:

- **Private labels:** its brand is in the list.
- **Other brands:** it has a brand, but it's not in the list.
- **Unknown brand:** it has no brand in the data.

The list is a table in the workbook, so a brand can be added without touching a formula.

### Dashboard content

Six charts, each of a different type. Four are for someone with diabetes: products by carb interval, share of sugar, carbs by package label and the most scanned products. Two are about the market: who makes the products and in which other countries they are sold.

<br>

## 9 November 2026

### Key numbers

Five cards on top of the dashboard, all counting validated products only, like the charts:

- **Products:** how many products there are.
- **Median carbs:** the carbs per 100g of the product in the middle, if you sort them all from fewest to most carbs.
- **Carb-free:** % of products with 0.5g of carbs or less per 100g.
- **Sugar-free:** % of products with 0.5g of sugar or less per 100g, out of the ones that have sugar data.
- **Brands:** how many different brands there are.

The median and not the average, because a few products near 100g, like sugar or flour, pull the average up to 24.2g. 0.5g is the limit the EU sets for "sugar free" claims, and I used the same for carbs.

<br>

## 10 November 2026

### Dashboard layout

Everything fits in one screen, on a grid of boxes of the same size:

- **Top:** the five key numbers, and the map on the right.
- **Middle:** on the left, the two carb charts. In the centre, the package labels chart and the brands doughnut. On the right, the most scanned products.
- **Bottom:** the filters.

The filters go at the bottom because the dashboard shows the whole market first, and the user filters only if they want to. Chart titles are text boxes outside the charts, so they all sit at the same height and use the same font.

**Left out:** a taller dashboard of 70 rows. It needed a 50% zoom to be seen whole, with half of the screen empty.

<br>

## 11 November 2026

### Chart by chart

- **Products in carb intervals:** columns, one per interval of 10g, with the share of products in each one. The 0-10g column is in a different colour, because almost half of the products are there. The rest share one colour.
- **Sugar in carb intervals:** a lollipop with how much of the carbs is sugar in each interval. Each point gets a colour by its value, from beige to red, and changes colour when a filter changes the value.
- **Does the label mean lower carbs?:** bars with the average carbs per 100g of the products that say "sugar free", "whole grain" or "gluten free" on the package, next to the ones that don't. A dashed line marks the top of the carb interval chosen in the filter, so a 24g bar doesn't look full when the interval is 20-30g.
- **Who makes the products:** a doughnut with the share of private labels, other brands and unknown brand.
- **Also sold in:** a map of 17 European countries, coloured by the share of the products sold in Spain that are also sold there. A card next to it shows the country with the highest share.
- **Most scanned in Spain:** the 10 most scanned products sold only in Spain, with their scans and their portions per 100g.

Pivot charts don't allow a lollipop and can lose their colours when the data refreshes. So the two carb charts are normal charts that read their numbers from cells, and the cells take them from the data model.

<br>

## 15 November 2026

### Filters

Five filters: carb interval, brand type, and one for each package label (sugar free, whole grain, gluten free). The labels have one filter each because a product can say more than one thing.

A filter doesn't change the chart that is already split by it. Picking private labels doesn't turn the doughnut into one full ring at 100%. It greys out the other brands, so you still see how big your choice is.

The label filters say "Says sugar free" because they filter by what the package says, not by the real sugar.

<br>

## 21 November 2026

### Quality sheet

A sheet that shows how far the data can be trusted: how many products were flagged, which check each one failed, what data is missing most often, and a few things to keep in mind when reading the dashboard.

### Look of the sheets

Every sheet has the same colours, fonts and orange title band. The font is Aptos, because it comes with Microsoft 365 and looks the same on any computer. The sheets for the user have orange tabs and the technical ones have grey tabs. Each sheet opens at a fixed zoom, so it looks the same every time.

### Where the data file is

Power Query needs the full address of the data file, and that address changes on every computer. If it was saved in the workbook, anyone who downloads it would see the folders of my computer. So the workbook doesn't keep it: a macro works it out every time the workbook opens, from the folder where the workbook is, and clears it just before saving.

<br>

## 22 November 2026

### Home sheet

The workbook opens on a cover with one card per sheet, each with a photo of the sheet and one line about what it does. Someone who opens the file for the first time knows where to go without reading anything else.
