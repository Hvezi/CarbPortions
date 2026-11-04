# Workbook formulas

## Search

### Named formulas

Stored in Formulas > Name Manager. Each one is used by several cells.

**SearchKey**
```
=REDUCE(LOWER(SearchTerm), {"áa","àa","ée","èe","íi","ïi","óo","òo","úu","üu","ñn","çc"}, LAMBDA(t, p, SUBSTITUTE(t, LEFT(p), RIGHT(p))))
```

LOWER turns the search into lowercase. REDUCE goes through each pair (accented letter and plain letter) and SUBSTITUTE replaces the first letter with the second. "MARÍA" becomes "maria". It does the same as *Unaccent* in *qSource* (D12).

**SearchHits**
```
=LET(words, TEXTSPLIT(TRIM(SearchKey), " "), text, tblProducts[search_name] & " " & tblProducts[search_brand], found, ISNUMBER(SEARCH(words, text)), n, COLUMNS(words), (MMULT(--found, SEQUENCE(n, 1, 1, 0)) = n) + (tblProducts[code] = SearchTerm))
```

- **words:** TRIM removes extra spaces and TEXTSPLIT cuts the clean search (*SearchKey*) by spaces: "galleta gullon" becomes {"galleta", "gullon"}.
- **text:** name and brand of each product without accents (*search_name* and *search_brand*), joined in one text.
- **found:** SEARCH looks for every word in every product. The result is a TRUE/FALSE grid: one row per product, one column per word.
- **n:** number of words.
- **Result:** `--found` turns TRUE/FALSE into 1/0, and MMULT by a column of ones (SEQUENCE) adds each row: the number of words found in each product. It is 1 only when that number equals *n*. The barcode check adds 1 when the code is exactly the search. The `+` works as OR.

**SearchTotal**
```
=Search!$P$3
```

Cell P3 holds `=SUM(SIGN(SearchHits))`. SIGN turns every match into 1 (a product can be 2 if it matches by name and barcode) and SUM counts them. A named formula is calculated again every time it is used, so the total lives in a cell and the name only points to it (D15).

**SearchPages**
```
=MAX(1, ROUNDUP(SearchTotal / ResultLimit, 0))
```

Matches divided by products per page, rounded up: 2,661 / 50 = 53.2, so 54 pages. MAX keeps it at 1 when there are no matches.

**CurrentPage**
```
=MIN(MAX(PageNumber, 1), SearchPages)
```

MAX stops pages below 1 and MIN stops pages above the last one. If the user asks for page 999 of 54, page 54 is shown.

### Results (cell B6)

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

**1. Find**
- **words:** the clean search split into words, the same as in *SearchHits*.
- **hits:** 1 or 0 for each product, from *SearchHits*.

**2. Reliability level (D13)**
- **check, errs:** *nutrition_check* and *data_quality_errors_tags* of the matching products.
- **level:** 3 (red) if *check* is "Check"; otherwise 2 (amber) if an error contains "nutrition"; otherwise 1 (green). An empty error cell makes SEARCH fail, so ISNUMBER returns FALSE and the level is 1.

**3. Filter**
- **rows:** FILTER keeps the matching rows of *tblProducts*, and HSTACK adds *level* as an extra column at the end (column 33, after the 32 columns of the table).
- **inName:** TRUE when every word is in *search_name* alone, without the brand (D6). The same MMULT count as *SearchHits*, but only on the names of the matching products (D15).
- **scans, compl:** the other sort columns, filtered the same way so they have the same size as *rows*.

**4. Sort**
- **sorted:** SORTBY with four rules, each one breaks ties of the one before: reliability level (1 first), all words in the name, most scanned, most complete. `1` means smallest first and `-1` largest first. TRUE counts as larger than FALSE.

**5. Page**
- **page:** the page to show, from *CurrentPage*.
- **top:** DROP removes the rows of the pages before, and TAKE keeps one page. Page 3 of 50: drop 100, take 50.

**6. Build the columns**
- **portions:** column 15 (*carbohydrates_100g*) divided by 10, with 1 decimal.
- **data:** CHOOSE turns the level (column 33) into its text: 1 "✔", 2 "Minor issue", 3 "⚠ Check label".
- **cols:** HSTACK joins the columns in order: CHOOSECOLS picks columns of *tblProducts* by position (1 code, 2 name, 3 brand, 11 package, 15 carbs, 17 sugars, 13 fat, 16 protein, 12 kcal), and the calculated *portions* and *data* go in their place.
- **clean:** empty cells become "–". A real 0 stays 0.
- **photo:** IMAGE downloads the photo from column 4 (*image_small_url*). IFERROR shows "–" when there is no photo. It is added after *clean* because a photo is not text or a number.

**7. Show**
- Empty search: "Type a product name or barcode".
- No match (OR finds no 1 in *hits*): "No results".
- Otherwise: photo on the left and the clean columns on the right.

### Counter (cell F3)

```
=IF(SearchTerm = "", "", IF(SearchTotal = 0, "", LET(first, (CurrentPage - 1) * ResultLimit + 1, last, MIN(CurrentPage * ResultLimit, SearchTotal), "Showing " & TEXT(first, "#,##0") & "–" & TEXT(last, "#,##0") & " of " & TEXT(SearchTotal, "#,##0"))))
```

- **first:** first product of the page. Page 54 of 50: (54 - 1) × 50 + 1 = 2,651.
- **last:** last product of the page. MIN stops it at the total on the last page.
- **TEXT:** adds the thousands separator (2,661).
- Empty when there is no search or no match.

### Page total (cell K3)

```
=IF(SearchTerm = "", "", IF(SearchTotal = 0, "", "of " & SearchPages))
```

### Links (cells N6:N105)

```
=IF(C6 = "", "", HYPERLINK("https://es.openfoodfacts.org/product/" & C6, "View"))
```

One formula per row, copied down from N6 to N105. Each row reads the barcode of its own row (column C). Rows without a product stay empty. It is not part of B6 because links inside a spilled result are not clickable (D8).


## Calculator

All formulas are calculated columns of *tblMeal*: written once, they fill the whole column. `[@Barcode]` means the barcode of the same row.

### Product (column D)

```
=IF([@Barcode] = "", "", XLOOKUP([@Barcode], tblProducts[code], tblProducts[product_name], "Not found"))
```

XLOOKUP looks for the barcode in *code* and returns *product_name* from the same row. "Not found" when the barcode doesn't exist. Empty when there is no barcode.

### Carbs (column E)

```
=IF(OR([@Barcode] = "", [@[Amount (g or ml)]] = ""), "", LET(c, XLOOKUP([@Barcode], tblProducts[code], tblProducts[carbohydrates_100g], ""), IF(c = "", "", ROUND(c * [@[Amount (g or ml)]] / 100, 1))))
```

- Empty when the barcode or the amount is missing.
- **c:** carbs per 100 g of the product, with the same XLOOKUP.
- Carbs per 100 g × amount / 100, with 1 decimal: 78 × 30 / 100 = 23.4.

### Portions (column F)

```
=IF([@[Carbs (g)]] = "", "", ROUND([@[Carbs (g)]] / 10, 1))
```

Carbs of the row divided by 10 (1 portion = 10 g of carbs).

### Total row (row 16)

- **Carbs:** `=SUBTOTAL(109, [Carbs (g)])`, the sum of the column. 109 is the code for SUM, ignoring hidden rows.
- **Portions:** `=ROUND(SUBTOTAL(109, [Carbs (g)]) / 10, 1)`, calculated from the total carbs. Adding the rounded portions of each row would add up rounding errors.