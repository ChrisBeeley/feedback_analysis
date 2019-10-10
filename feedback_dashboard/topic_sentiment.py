
## this is the topic modelling bit

# %% load packages
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer, CountVectorizer
from sklearn.decomposition import NMF
import numpy as np
import inspect

# %%

# feedback = pd.read_csv("/home/chris/Nextcloud/feedback_analysis/for_gensim.csv", encoding = "latin-1", na_values=[])

feedback = pd.read_csv("/home/chris/Nextcloud/feedback_analysis/leicester.csv", encoding = "latin-1", na_values=[])

feedback["word_count"] = feedback["Improve"].apply(lambda x: len(x.split()))

feedback = feedback[feedback['word_count'] > 10]

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

topic_words = []
topic_documents = []

for topic_idx, topic in enumerate(nmf_H):
    top_doc_indices = np.argsort(nmf_W[:,topic_idx] )[::-1][0:no_top_documents]
    topic_documents.append([documents[i] for i in top_doc_indices])
    topic_words.append(" ".join([tfidf_feature_names[i]
                    for i in topic.argsort()[:-no_top_words - 1:-1]]))

# %% this next bit is to write which topic every document belongs to

results = np.apply_along_axis(lambda x : np.argmax(x), 1, nmf_W)

feedback["topic"] = results

# save the topic models

feedback = feedback.reset_index()

feedback.to_feather('topic_modelled.feather')

# now save what they are

pd.DataFrame(topic_words, columns = ["words"]).to_feather("topics.feather")

# pd.DataFrame(topic_documents, columns = ["V1", "V2", "V3", "V4", "V5", "V6", "V7", "V8", "V9", "V10"]).to_feather("topic_documents.feather")

## and this is the sentiment bit

# %% package loads

# ! pip install vaderSentiment

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer

# %% analysis

analyser = SentimentIntensityAnalyzer()

my_score = feedback.Improve.apply(analyser.polarity_scores)

feedback["sentiment"] = my_score.apply(lambda x: x["compound"])

feedback.to_feather('vader.feather')
