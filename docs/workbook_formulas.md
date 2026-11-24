# Workbook formulas

Every formula of the workbook, copied exactly as it is, and what each part does. Where each sheet keeps them is in [workbook_structure.md](workbook_structure.md), and why they are built this way is in [decisions.md](decisions.md).

<br>

## Search

### Named formulas

They live in Formulas > Name Manager, not in cells. Several cells use them, so each calculation is written once.

**SearchKey:** the search in lowercase and without accents.

```
=REDUCE(LOWER(SearchTerm), {"áa","àa","ée","èe","íi","ïi","óo","òo","úu","üu","ñn","çc"}, LAMBDA(t,p, SUBSTITUTE(t, LEFT(p), RIGHT(p))))
```

LOWER turns the search into lowercase. The list has pairs of letters, the accented one and the plain one. REDUCE goes through the pairs one by one, and SUBSTITUTE swaps the first letter for the second. "MARÍA" becomes "maria", the same way Power Query cleans *search_name*.

**SearchHits:** for every product, 1 if it matches the search and 0 if not.

```
=LET(words, TEXTSPLIT(TRIM(SearchKey), " "), text, tblProducts[search_name] & " " & tblProducts[search_brand], found, ISNUMBER(SEARCH(words, text)), n, COLUMNS(words), (MMULT(--found, SEQUENCE(n, 1, 1, 0)) = n) + (tblProducts[code] = SearchTerm))
```

Step by step, searching "galleta gullon":

1. **words:** the search cut by spaces, {"galleta", "gullon"}.
2. **text:** the name and brand of every product, joined in one text.
3. **found:** SEARCH looks for each word in each product. The result is a grid of TRUE and FALSE, one row per product and one column per word.
4. **n:** how many words there are, 2.
5. **The result:** MMULT adds up each row of the grid, so it gives how many words each product has. A product matches when it has all of them (the count equals *n*). The second part adds 1 when the barcode is exactly the search. The `+` works as "or".

**SearchTotal:** the number of matches.

```
=Search!$P$7
```

The hidden cell P7 holds `=SUM(SIGN(SearchHits))`. SIGN turns every match into 1 (a product that matches by name and by barcode would be 2) and SUM counts them. A named formula is calculated again every time it is used, so the total is stored in a cell and the name only reads it.

**SearchPages:** the number of pages.

```
=MAX(1, ROUNDUP(SearchTotal / ResultLimit, 0))
```

Matches divided by products per page, rounded up: 2,661 / 50 = 53.2, so 54 pages. MAX keeps it at 1 when there are no matches.

**CurrentPage:** the page really shown.

```
=MIN(MAX(PageNumber, 1), SearchPages)
```

MAX stops it from going below 1 and MIN from going past the last page. Page 999 of 54 shows page 54.

### Results (B11)

One formula that fills the whole page of results.

```
=LET(
    words, TEXTSPLIT(TRIM(SearchKey), " "),
    hits, SearchHits,
    check, FILTER(tblProducts[nutrition_check], hits),
    errs, FILTER(tblProducts[data_quality_errors_tags], hits),
    level, IF(check = "Check", 3, IF(ISNUMBER(SEARCH("nutrition", errs)), 2, 1)),
    rows, HSTACK(FILTER(tblProducts, hits), level),
    inName, MMULT(--ISNUMBER(SEARCH(words, FILTER(tblProducts[search_name], hits))), SEQUENCE(COLUMNS(words), 1, 1, 0)) = COLUMNS(words),
    scans, FILTER(tblProducts[unique_scans_n], hits),
    compl, FILTER(tblProducts[completeness], hits),
    sorted, SORTBY(rows, level, 1, inName, -1, scans, -1, compl, -1),
    page, CurrentPage,
    top, TAKE(DROP(sorted, (page - 1) * ResultLimit), ResultLimit),
    portions, ROUND(CHOOSECOLS(top, 15) / 10, 1),
    data, CHOOSE(CHOOSECOLS(top, 33), "✔", "Minor issue", "⚠ Check label"),
    cols, HSTACK(CHOOSECOLS(top, 1, 2, 3, 11, 15), portions, CHOOSECOLS(top, 17, 13, 16, 12), data),
    clean, IF(cols = "", "–", cols),
    photo, IFERROR(IMAGE(CHOOSECOLS(top, 4)), "–"),
    IF(SearchTerm = "", "Type a product name or barcode", IF(OR(hits), HSTACK(photo, clean), "No results"))
)
```

It works in seven steps.

1. **Find:** *words* are the search words and *hits* says which products match.
2. **Reliability level:** for the matching products, *level* is 3 if *nutrition_check* says "Check", 2 if the Open Food Facts errors mention "nutrition", and 1 otherwise.
3. **Filter:** *rows* keeps only the matching products and adds the level as an extra column at the end (column 33). *inName* is TRUE when all the words are in the name, without counting the brand. *scans* and *compl* are the scans and completeness of the same products.
4. **Sort:** SORTBY uses four rules. Lowest level first, then products with every word in the name, then the most scanned, then the most complete. `1` means smallest first and `-1` largest first.
5. **Page:** DROP skips the products of the pages before, and TAKE keeps one page. Page 3 with 50 per page skips 100 and keeps 50.
6. **Columns:** CHOOSECOLS picks columns of the table by their number: 1 barcode, 2 name, 3 brand, 11 package, 15 carbs, 17 sugars, 13 fat, 16 protein, 12 kcal. *portions* is carbs divided by 10, and *data* turns the level into its text. HSTACK puts them all in order. *clean* shows "–" in empty cells, and a real 0 stays 0. *photo* downloads the photo with IMAGE, or shows "–" if there is none.
7. **Show:** "Type a product name or barcode" if the search is empty, "No results" if nothing matches, and otherwise the photo next to the columns.

### Counter (C8)

```
=IF(SearchTerm = "", "", IF(SearchTotal = 0, "", LET(first, (CurrentPage - 1) * ResultLimit + 1, last, MIN(CurrentPage * ResultLimit, SearchTotal), "Showing " & TEXT(first, "#,##0") & "–" & TEXT(last, "#,##0") & " of " & TEXT(SearchTotal, "#,##0"))))
```

*first* is the first product of the page and *last* the last one, which MIN stops at the total on the last page. Page 54 with 50 per page: from 2,651 to 2,661. TEXT adds the thousands separator. It stays empty with no search or no matches.

### Page total (K7)

```
=IF(SearchTerm = "", "", IF(SearchTotal = 0, "", "of " & SearchPages))
```

### Links (N11 to N110)

```
=IF(C11 = "", "", HYPERLINK("https://es.openfoodfacts.org/product/" & C11, "View"))
```

One formula per row, copied down. Each row builds the link from the barcode of its own row, and rows without a product stay empty. The links can't be part of the results formula, because links inside a spilled formula can't be clicked.

<br>

## Calculator

The three columns of *tblMeal* are calculated columns: written once, they fill the whole column. `[@Barcode]` means "the barcode of this row".

### Product (column E)

```
=IF([@Barcode] = "", "", LET(n, XLOOKUP([@Barcode], tblProducts[code], tblProducts[product_name], "Not found"), IF(LEN(n) > 36, LEFT(n, 35) & "…", n)))
```

XLOOKUP looks for the barcode in the product table and returns its name, or "Not found". Names longer than 36 characters are cut and end in "…", so they fit in the column.

### Carbs (column F)

```
=IF(OR([@Barcode] = "", [@[Amount (g or ml)]] = ""), "", LET(c, XLOOKUP([@Barcode], tblProducts[code], tblProducts[carbohydrates_100g], ""), IF(c = "", "", ROUND(c * [@[Amount (g or ml)]] / 100, 1))))
```

Empty until the row has a barcode and an amount. *c* is the carbs per 100g of the product. Then carbs per 100g × amount ÷ 100, with 1 decimal: 50 × 60 ÷ 100 = 30.

### Portions (column G)

```
=IF([@[Carbs (g)]] = "", "", ROUND([@[Carbs (g)]] / 10, 1))
```

The carbs of the row divided by 10.

### Screen (K1 and K2, hidden)

```
=TEXT(SUM(tblMeal[Carbs (g)]),"0.0")&"g"
=TEXT(SUM(tblMeal[Carbs (g)])/10,"0.0")
```

Total carbs and total portions of the meal. SUM skips the empty rows. The portions come from the total carbs, not from adding up the rounded portions of each row.

<br>

## Quality

Everything is in the hidden columns AH to AL. Column AI has the numbers, and AJ and AK have what the cards and charts show.

### Cards (AI1 to AI4)

```
=ROWS(tblProducts)
=COUNTIF(tblProducts[nutrition_check],"OK")
=COUNTIF(tblProducts[nutrition_check],"Check")
=COUNTIFS(tblProducts[nutrition_check],"OK",tblProducts[data_quality_errors_tags],"*nutrition*")
```

Products in the file, validated, flagged, and validated but with a nutrition error from Open Food Facts (the "Minor issue" of Search). Next to them, `=TEXT(AI1,"#,##0")` in AJ gives each number its format, and AK2 has the share of the file, `=TEXT(AI2/AI1,"0.0%")&" of the file"`.

### Why products are flagged (AI7 to AI11)

One formula per check of *nutrition_check*. SUMPRODUCT with `--` counts how many products are TRUE.

```
=SUMPRODUCT(--(tblProducts[sugars_100g]>tblProducts[carbohydrates_100g]))
=SUMPRODUCT((tblProducts[fat_100g]<>"")*(tblProducts[saturated-fat_100g]>tblProducts[fat_100g]))
=SUMPRODUCT(--(tblProducts[fat_100g]+tblProducts[carbohydrates_100g]+tblProducts[proteins_100g]>105))
=COUNTIF(tblProducts[energy-kcal_100g],">900")
=LET(k,tblProducts[energy-kcal_100g],c,tblProducts[carbohydrates_100g],pr,tblProducts[proteins_100g],f,tblProducts[fat_100g],po,tblProducts[polyols_100g],fi,tblProducts[fiber_100g],calc,4*(c-po)+2.4*po+4*pr+9*f+2*fi,d,ABS(k-calc),SUM((k<>"")*(pr<>"")*(f<>"")*(d>50)*(d>0.5*calc)))
```

1. More sugar than carbs.
2. More saturated fat than fat.
3. Fat, carbs and protein adding up to more than 105g per 100g.
4. More than 900 kcal per 100g.
5. Kcal that don't match the nutrients. *calc* works out the kcal from the nutrients with the EU factors (4 per gram of carbs and protein, 9 fat, 2.4 polyols, 2 fibre). A product counts when the difference *d* is more than 50 kcal and more than half of *calc*. Only products with kcal, protein and fat are checked.

`=SORTBY(AH7:AI11,AI7:AI11,1)` in AK7 sorts the five checks from fewest to most products. The chart reads that sorted list, so the longest bar ends up on top.

### Missing data (AI14 to AI19)

```
=COUNTBLANK(tblProducts[sugars_100g])/ROWS(tblProducts)
=1-SUM(COUNTIF(tblProducts[nutriscore_grade],{"a","b","c","d","e"}))/ROWS(tblProducts)
```

Empty cells divided by all products. The first line is sugars, and the same formula is repeated for fibre, serving size, brand and category. Nutri-Score is different: "not-applicable" is not empty but isn't a grade either, so it counts the products with a grade from a to e and takes the rest. AK14 sorts them the same way as the flagged checks.

### Download date (AH22)

```
="Data downloaded on "&DAY(Settings!$C$7)&" "&CHOOSE(MONTH(Settings!$C$7),"January","February","March","April","May","June","July","August","September","October","November","December")&" "&YEAR(Settings!$C$7)
```

Built piece by piece instead of with TEXT, because the date codes of TEXT change with the language of Excel. In a Spanish Excel, "yyyy" doesn't work.

<br>

## Settings

```
=HYPERLINK("https://world.openfoodfacts.org/data", "Open Food Facts")
=ROWS(tblProducts)
```

C3, C5 and C17 are links built with HYPERLINK, and C9 counts the products of the table. The rest are typed by hand.

<br>

## Data model (DAX)

### Columns

Calculated row by row inside the model. They don't exist in the Data sheet.

**carb_band:** the 10g interval of the product.

```
= VAR b = MIN(FLOOR([carbohydrates_100g], 10), 90) RETURN b & "-" & b + 10 & "g"
```

FLOOR rounds down to the 10 below: 24.5 becomes 20, so "20-30g". MIN puts products with exactly 100g in the last interval, "90-100g".

**sugar_free, whole_grain, gluten_free:** "Yes" if the name says it.

```
= IF(SEARCH("sin azucar", [search_name], 1, 0) + SEARCH("sugar free", [search_name], 1, 0) + SEARCH("0% azucar", [search_name], 1, 0) + SEARCH("zero", [search_name], 1, 0) > 0, "Yes", "No")
```

SEARCH gives 0 when it doesn't find the text. If any of the words is found, the sum is above 0 and the answer is "Yes". *whole_grain* looks for "integral", "whole grain", "wholegrain" and "whole wheat", and *gluten_free* for "sin gluten", "gluten free" and "glutenfree".

**brand_type:** private label, other brand or unknown.

```
= VAR b = [search_brand] VAR matches = COUNTROWS(FILTER(tblPrivateLabels, b = tblPrivateLabels[brand] || LEFT(b, LEN(tblPrivateLabels[brand]) + 1) = tblPrivateLabels[brand] & " ")) RETURN IF(b = "", "Unknown brand", IF(matches > 0, "Private labels", "Other brands"))
```

*matches* counts the supermarket brands that are the brand of the product, or that it starts with followed by a space ("carrefour bio" starts with "carrefour "). No brand gives "Unknown brand", at least one match gives "Private labels", and the rest are "Other brands".

**main_brand:** the first brand of the product.

```
= VAR b = [search_brand] VAR p = SEARCH(",", b, 1, 0) RETURN IF(p = 0, b, TRIM(LEFT(b, p - 1)))
```

*p* is where the first comma is. If there is none, the whole brand. If there is one, the text before it: "hacendado, mercadona" gives "hacendado".

**name_and_brand:** the name and the brand together.

```
= [product_name] & IF(ISBLANK([brands_en]), "", " · " & [brands_en])
```

Used in the most scanned list, so two products with the same name and a different brand don't merge into one row.

### Measures

```
Products := CALCULATE(COUNTROWS(tblProducts), tblProducts[nutrition_check] = "OK")
Products % := DIVIDE([Products], CALCULATE([Products], ALLSELECTED(tblProducts)))
Sugar % := VAR s = CALCULATE(SUM(tblProducts[sugars_100g]), tblProducts[nutrition_check] = "OK", NOT ISBLANK(tblProducts[sugars_100g])) VAR c = CALCULATE(SUM(tblProducts[carbohydrates_100g]), tblProducts[nutrition_check] = "OK", NOT ISBLANK(tblProducts[sugars_100g])) RETURN DIVIDE(s, c)
Avg carbs := CALCULATE(AVERAGE(tblProducts[carbohydrates_100g]), tblProducts[nutrition_check] = "OK")
Avg sugars := CALCULATE(AVERAGE(tblProducts[sugars_100g]), tblProducts[nutrition_check] = "OK")
Carbs with label := VAR c = IF(HASONEVALUE(tblLabels[Label says]), VALUES(tblLabels[Label says])) RETURN CALCULATE([Avg carbs], FILTER(tblProducts, SWITCH(c, "Sugar free", tblProducts[sugar_free], "Whole grain", tblProducts[whole_grain], "Gluten free", tblProducts[gluten_free]) = "Yes"))
Carbs without label := VAR c = IF(HASONEVALUE(tblLabels[Label says]), VALUES(tblLabels[Label says])) RETURN CALCULATE([Avg carbs], FILTER(tblProducts, SWITCH(c, "Sugar free", tblProducts[sugar_free], "Whole grain", tblProducts[whole_grain], "Gluten free", tblProducts[gluten_free]) = "No"))
Portions per 100 g := CALCULATE(AVERAGE(tblProducts[carbohydrates_100g]), tblProducts[nutrition_check] = "OK") / 10
Scans ES := CALCULATE(SUM(tblProducts[unique_scans_n]), tblProducts[nutrition_check] = "OK", tblProducts[countries_tags] = "en:spain")
Also sold in := VAR t = IF(HASONEVALUE(tblCountries[tag]), VALUES(tblCountries[tag])) RETURN CALCULATE([Products], FILTER(tblProducts, SEARCH(t, tblProducts[countries_tags], 1, 0) > 0))
Also sold in % := DIVIDE([Also sold in], [Products])
Median carbs := CALCULATE(MEDIAN(tblProducts[carbohydrates_100g]), tblProducts[nutrition_check] = "OK")
Carb-free % := DIVIDE(CALCULATE([Products], tblProducts[carbohydrates_100g] <= 0.5), [Products])
Sugar-free % := DIVIDE(CALCULATE([Products], tblProducts[sugars_100g] <= 0.5, NOT ISBLANK(tblProducts[sugars_100g])), CALCULATE([Products], NOT ISBLANK(tblProducts[sugars_100g])))
Brands := CALCULATE(DISTINCTCOUNT(tblProducts[main_brand]), tblProducts[nutrition_check] = "OK", tblProducts[main_brand] <> "")
```

- **CALCULATE** runs a calculation with extra filters. Almost every measure adds `nutrition_check = "OK"`, so only validated products count.
- **Products %:** the products of a row divided by all the products. ALLSELECTED ignores the row (an interval, a brand type) but keeps the filters the user picked.
- **Sugar %:** all the sugar divided by all the carbs of the group, counting only products that have sugar data.
- **Carbs with label / without label:** HASONEVALUE and VALUES read which label the row is about ("Sugar free"). SWITCH picks the column of that label, and FILTER keeps the products with "Yes", or with "No".
- **Scans ES:** scans of the products sold only in Spain.
- **Also sold in:** reads the tag of the country ("en:france") and counts the products whose list of countries contains it. *Also sold in %* divides that by all the products.
- **Carb-free % and Sugar-free %:** products with 0.5g or less per 100g, divided by all products. For sugar, only products with sugar data count, on both sides of the division.
- **Brands:** DISTINCTCOUNT counts each brand once. `<> ""` leaves out products without a brand, which would count as one more brand.

<br>

## AnalysisData

### CUBEVALUE and the filters

CUBEVALUE asks the data model for one number: which measure and with which filters. The filters the user picks on the dashboard are passed in by name (*Slicer_carb_band*, *Slicer_brand_type*…), so the number changes when the user filters. That's how cells, which aren't pivot tables, still react to the filters.

### Carb chart (F3 to F12)

```
=CUBEVALUE("ThisWorkbookDataModel", Slicer_brand_type, Slicer_sugar_free, Slicer_whole_grain, Slicer_gluten_free, "[Measures].[Products]", "[tblProducts].[carb_band].&[" & E3 & "]") / CUBEVALUE("ThisWorkbookDataModel", Slicer_brand_type, Slicer_sugar_free, Slicer_whole_grain, Slicer_gluten_free, "[Measures].[Products]")
```

The products of one interval divided by all the products. The interval comes from column E, typed as text ('0-10g) so Excel doesn't turn it into a date. The carb interval filter is left out on purpose, because this chart is already split by interval.

### Sugar chart (F18 to F27, and G to J)

```
=CUBEVALUE("ThisWorkbookDataModel", Slicer_brand_type, Slicer_sugar_free, Slicer_whole_grain, Slicer_gluten_free, "[Measures].[Sugar %]", "[tblProducts].[carb_band].&[" & E18 & "]")
```

The share of sugar of each interval. The intervals in E18:E27 are typed as text too.

Columns G to J give each point its colour. Each column is one colour of the chart, and copies the value only if it falls in its range:

| Column | Range | Formula (row 18) |
|---|---|---|
| G | 50% or more | `=IF(F18>=0.5, F18, NA())` |
| H | 40% to 50% | `=IF(AND(F18>=0.4, F18<0.5), F18, NA())` |
| I | 30% to 40% | `=IF(AND(F18>=0.3, F18<0.4), F18, NA())` |
| J | Less than 30% | `=IF(F18<0.3, F18, NA())` |

Charts don't draw #N/A, so each interval shows only one point, in the colour of its range. When a filter changes a value, the point moves to another column and changes colour.

### Map (column D of tblCountries, D122 to D138)

```
=CUBEVALUE("ThisWorkbookDataModel", Slicer_carb_band, Slicer_brand_type, Slicer_sugar_free, Slicer_whole_grain, Slicer_gluten_free, "[Measures].[Also sold in %]", "[tblCountries].[Country].&[" & B122 & "]")
```

The share of products also sold in the country of that row. Filled maps can't read pivot tables, so the map reads this column.

### Map card (B140 to B142)

```
=XLOOKUP(MAX(tblCountries[Also sold in %]), tblCountries[Also sold in %], tblCountries[Country])
=TEXT(MAX(tblCountries[Also sold in %]), "0.00%")
=TEXT(CUBEVALUE("ThisWorkbookDataModel", "[Measures].[Also sold in]", "[tblCountries].[Country].&[" & B140 & "]", Slicer_carb_band, Slicer_brand_type, Slicer_sugar_free, Slicer_whole_grain, Slicer_gluten_free), "#,##0") & " products"
```

The country with the highest share, its share and its number of products. MAX finds the highest share and XLOOKUP returns its country. Sorting the table wouldn't work: a country with no products for the current filter gets an empty text, and sorting puts text before numbers.

### Key numbers (B147, B150, B153, B156, B159)

```
=TEXT(CUBEVALUE("ThisWorkbookDataModel", Slicer_carb_band, Slicer_brand_type, Slicer_sugar_free, Slicer_whole_grain, Slicer_gluten_free, "[Measures].[Products]"), "#,##0")
```

The same formula in each card, changing the measure and the format:

| Cell | Card | Measure | Format |
|---|---|---|---|
| B147 | Products | Products | `"#,##0"` |
| B150 | Median carbs | Median carbs | `"0.0"` and "g" |
| B153 | Carb-free | Carb-free % | `"0.0%"` |
| B156 | Sugar-free | Sugar-free % | `"0.0%"` |
| B159 | Brands | Brands | `"#,##0"` |

TEXT gives the number its format. Without it, CUBEVALUE overwrites the format of the cell.
