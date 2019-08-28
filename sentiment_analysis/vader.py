
# %% package loads

# ! pip install vaderSentiment

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer

df_all = pd.read_csv('for_gensim.csv')

# %% analysis

analyser = SentimentIntensityAnalyzer()

my_score = df_all.Keep_Improve.apply(analyser.polarity_scores)

df_all["my_compound"] = my_score.apply(lambda x: x["compound"])

df_all.to_feather('vader.feather')
