# Blinkit: problem understanding

Pranjal Garg | T0133

The database connects customers, nearby dark stores, products and riders.
Fast app screens matter, but reports also need to finish in time for managers
to use them. These are the seven problems in the brief.

| Problem | What is needed and who needs it | Type | Queries |
|---|---|---|---|
| P1 | A customer should quickly find a nearby active store, search products and check stock/price before adding items to the cart. | Customer-facing / real-time | R01-R05 |
| P2 | Checkout should create an order without a long wait. The customer and support team also need its latest tracking details. | Customer-facing / real-time | R06, W01 |
| P3 | Store managers and packers need an up-to-date queue. Dispatch should find a rider, and packing should deduct the correct stock. | Real-time store operations | R07, R21, W02, W03 |
| P4 | Replenishment staff need low-stock lists, recent restocks and products that are not selling. Restocking must update the inventory. | Operations: R09/W04 are real-time; R18/R24 are reporting | R09, R18, R24, W04 |
| P5 | The category team needs a correct list of products not used as substitutes. An empty result may be a query mistake, so speed alone is not enough. | Reporting / analytics | R13 |
| P6 | Operations managers need delivery delays, shortages, waste and rider/staffing reports to plan the next shift. | Reporting / analytics | R08, R10, R11, R14, R15 |
| P7 | Growth and finance need sales, fees, repeat-customer and recommendation reports as data grows. Support needs usable order pagination; retention runs as a batch job. | Mostly reporting / analytics; R22 is interactive support and W05 is batch | R12, R16, R17, R19, R20, R22-R25, W05 |

## Assumptions

- Use the supplied exports and exact table/column names. Keep the baseline
  workload unchanged, including any correctness problems found in it.
- Keep money as exact decimals and use timezone-aware timestamps. Report dates
  are interpreted in Asia/Kolkata, matching the export's +05:30 offset.
- A product can be stocked at many stores. Stock and selling price belong to
  the store-product pair, not just to the product.
- Missing email, shelf life, rider, timeline fields and substitutes can have
  valid meanings. A cancelled order may already have been packed.
- For CP2, measure the seed data with only the indexes made by key constraints.
  Later optimization must keep the results correct and explain any bug fix.
