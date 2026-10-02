import streamlit as st
import pandas as pd
import numpy as np
import joblib
from pathlib import Path

# ---------- Load model and data ----------
BASE = Path(__file__).resolve().parent.parent   # the project folder

@st.cache_resource
def load_model():
    model = joblib.load(BASE / "models" / "price_model.pkl")
    categories = joblib.load(BASE / "models" / "categories.pkl")
    return model, categories

@st.cache_data
def load_data():
    lookup = pd.read_csv(BASE / "app" / "Data" / "district_lookup.csv")
    trend = pd.read_csv(BASE / "app" / "Data" / "district_trend.csv")
    return lookup, trend

model, categories = load_model()
lookup, trend = load_data()

FEATURES = ["property_type_label", "new_build", "tenure",
            "postcode_district", "county", "sale_year", "sale_month"]

# ---------- Page layout ----------
st.set_page_config(page_title="UK House Price Estimator", page_icon="🏠")
st.title("🏠 UK House Price Estimator")
st.write("Estimate a property's price using a LightGBM model trained on "
         "HM Land Registry sales in England and Wales (2021–2024).")

# ---------- User inputs ----------
district = st.selectbox("Postcode district", sorted(lookup["postcode_district"]),
                        index=None, placeholder="Type a district, e.g. E17")
ptype = st.selectbox("Property type", ["Detached", "Semi-detached", "Terraced", "Flat"])
tenure = st.radio("Tenure", ["Freehold", "Leasehold"], horizontal=True)
new_build = st.checkbox("New build")

# ---------- Prediction ----------
if st.button("Estimate price", type="primary"):
    if district is None:
        st.warning("Please choose a postcode district first.")
    else:
        county = lookup.loc[lookup["postcode_district"] == district, "county"].iloc[0]

        # Build one row in exactly the same format the model was trained on
        row = pd.DataFrame([{
            "property_type_label": ptype,
            "new_build": "Y" if new_build else "N",
            "tenure": "F" if tenure == "Freehold" else "L",
            "postcode_district": district,
            "county": county,
            "sale_year": 2025,
            "sale_month": 6,
        }])[FEATURES]

        for col, cats in categories.items():
            row[col] = pd.Categorical(row[col], categories=cats)

        price = float(np.exp(model.predict(row))[0])
        low, high = price * 0.82, price * 1.18   # ±18%, the model's typical error

        st.metric("Estimated price", f"£{price:,.0f}")
        st.caption(f"Typical range: £{low:,.0f} – £{high:,.0f} · {district}, {county.title()}")

        # ---------- Price history chart ----------
        history = trend[(trend["postcode_district"] == district) &
                        (trend["property_type_label"] == ptype)].sort_values("sale_year")

        if history.empty:
            st.info("No recorded sales of this property type in this district.")
        else:
            st.subheader(f"Median {ptype.lower()} price in {district}")
            chart = history.set_index("sale_year")["median_price"]
            chart.index = chart.index.astype(str)
            st.line_chart(chart)
            if history["sales"].sum() < 30:
                st.warning("Few sales of this type here, so this estimate is less reliable.")

st.divider()
st.caption("Estimates are based on location and property type only. The data has no "
           "information on size, bedrooms or condition, so actual prices can differ a lot.")