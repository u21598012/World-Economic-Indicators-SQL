import pandas as pd
import plotly.express as px

def preprocess_columns(dataframe):
    return dataframe.columns.str.lower().str.replace(' ','_')

wbi = pd.read_csv("WBI.csv")
wbi.columns = preprocess_columns(wbi)

co2 = pd.read_csv("CO2.csv")
co2.columns = preprocess_columns(co2)

eah = pd.read_csv("EcandHDI.csv")
eah.columns = preprocess_columns(eah)

av_hdi = pd.read_csv("AveHDI.csv")
av_hdi.columns = preprocess_columns(av_hdi)


co2['average_co2_production_for_2021'] = pd.to_numeric(co2['average_co2_production_for_2021'], errors='coerce')
bar_data = co2.nlargest(5, 'average_co2_production_for_2021')

fig = px.bar(bar_data, x='country', y='average_co2_production_for_2021',
             title="Top 5 Countries by Average CO2 Emissions",
             labels={'average_co2_production_for_2021': 'Average CO2 Production for 2021', 'country': 'Country'})

fig.show()

fig_hdi = px.line(av_hdi, x='country', y=['average_hdi_2019', 'average_hdi_2020', 'average_hdi_2021', 'average_hdi_2019-2021'],
                  title="Average HDI Trends Over Years",
                  labels={'value': 'HDI Value', 'year': 'Year'})
fig_hdi.show()

# Create scatter plot
fig_development = px.scatter(
    development,
    x="avg_gdp", 
    y="avg_hdi",
    hover_name="country_name",
    hover_data=["avg_hdi_rank", "avg_gdp_score"],
    text="country_name",
    title="Human Development vs GDP per Capita",
    labels={
        'avg_gdp': 'GDP per Capita (USD)',
        'avg_hdi': 'Human Development Index',
        'country_name': 'Country'
    },
    height=600,
    width=800
)

# Improve readability
fig_development.update_traces(
    textposition='top center',
    marker=dict(size=12),
    textfont=dict(size=10)
)

# Add a trend line
fig_development.update_layout(
    xaxis_type="log",  # Log scale for GDP often shows the relationship better
    xaxis_title="GDP per Capita (Log Scale)",
    yaxis_title="Human Development Index (HDI)"
)

# Show the plot
fig_development.show()
# print(co2)
