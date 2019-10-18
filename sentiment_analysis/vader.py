
# %% package loads

# ! pip install vaderSentiment

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer

# df_all = pd.read_csv('for_gensim.csv')

# leicester DataFrame

df_all = pd.read_csv("/home/chris/Nextcloud/feedback_analysis/leicester.csv", encoding = "latin-1", na_values=[])

# %% analysis

analyser = SentimentIntensityAnalyzer()

my_score = df_all.Improve.apply(analyser.polarity_scores)

df_all["sentiment"] = my_score.apply(lambda x: x["compound"])

df_all.to_feather('vader_leicester.feather')

df_all.to_csv(path_or_buf = "leicester_sentiment.csv", index=False)
