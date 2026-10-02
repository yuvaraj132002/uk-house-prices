## Model results (tested on 2025 sales)

| Model | MAE (£) | MAPE (%) | Median error (%) |
|---|---------|----------|------------------|
| Baseline | 94446   | 25.2     | 18.2             |
| Linear regression | 96634   | 27.0     | 19.2             |
| LightGBM | 92417   | 24.9     | 18.0    
LightGBM performed best, with a typical error of 18% on unseen 2025 sales, but it only slightly outperformed the baseline, which predicts the median price for the same property type in the same postcode district. Linear regression performed worse than the baseline. This shows that location and property type explain most of the variation in price that is available in this dataset. Because the Land Registry data contains no information about a property's size, number of bedrooms or condition, the model cannot distinguish between very different homes in the same area, which limits its accuracy. The most promising next step would be to add floor area from EPC data, along with location coordinates and deprivation scores, to give the model more information to work with.