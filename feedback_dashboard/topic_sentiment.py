
## this is the topic modelling bit

# %% load packages
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer, CountVectorizer
from sklearn.decomposition import NMF
import numpy as np
import inspect

# %%

feedback = pd.read_csv("/home/chris/Nextcloud/feedback_analysis/for_gensim.csv", encoding = "latin-1", na_values=[])

# convert the 2nd column values to a list
documents = feedback["Improve"].tolist()

# %% 10 topics

no_topics = 10
no_top_words = 8
no_top_documents = 10

# NMF is able to use tf-idf
tfidf_vectorizer = TfidfVectorizer(max_df=0.95, min_df=2, stop_words='english')
tfidf = tfidf_vectorizer.fit_transform(documents)
tfidf_feature_names = tfidf_vectorizer.get_feature_names()

# Run NMF
nmf_model = NMF(n_components=no_topics, random_state=1, alpha=.1, l1_ratio=.5, init='nndsvd').fit(tfidf)
nmf_W = nmf_model.transform(tfidf)
nmf_H = nmf_model.components_

# %% so I selected 10 topics. Let's dump the whole thing to R

# this bit works and produces a list of topic headings
# and in the same order to top words from those headings

topic_heading  = []
topic_words = []

for topic_idx, topic in enumerate(nmf_H):
    topic_heading.append("Topic %d:" % (topic_idx))
    topic_words.append(" ".join([tfidf_feature_names[i]
                    for i in topic.argsort()[:-no_top_words - 1:-1]]))

# %% this next bit is to write which topic every document belongs to

results = np.apply_along_axis(lambda x : np.argmax(x), 1, nmf_W)

feedback["topic"] = results

# save the topic models

feedback.to_feather('topic_modelled.feather')

# now save what they are

pd.DataFrame(topic_words, columns = ["words"]).to_feather("topics.feather")

## and this is the sentiment bit

# %% package loads

# ! pip install vaderSentiment

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer

# %% analysis

analyser = SentimentIntensityAnalyzer()

my_score = feedback.Keep_Improve.apply(analyser.polarity_scores)

feedback["sentiment"] = my_score.apply(lambda x: x["compound"])

feedback.to_feather('vader.feather')
