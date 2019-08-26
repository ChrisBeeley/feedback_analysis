
# %% load packages
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer, CountVectorizer
from sklearn.decomposition import NMF, LatentDirichletAllocation
import numpy as np
import inspect

# %%

feedback = pd.read_csv("/home/chris/Nextcloud/feedback_analysis/for_gensim.csv", encoding = "latin-1", na_values=[])

# convert the 2nd column values to a list
documents = feedback["Improve"].tolist()

# feedback.head(n = 5)

# %% write a document with the topics in

no_top_words = 8
no_top_documents = 10

from docx import Document
from docx.shared import Inches

def display_topics(H, W, feature_names, documents, no_top_words, no_top_documents):
    for topic_idx, topic in enumerate(H):
        document.add_heading("Topic %d:" % (topic_idx), 1)
        document.add_heading(" ".join([feature_names[i]
                        for i in topic.argsort()[:-no_top_words - 1:-1]]), 2)
        top_doc_indices = np.argsort( W[:,topic_idx] )[::-1][0:no_top_documents]
        for doc_index in top_doc_indices:
            document.add_paragraph(documents[doc_index])
        document.add_page_break()

# %% five topics

no_topics = 5

document = Document()

document.add_heading('Topics', 0)

# Run NMF
nmf_model = NMF(n_components=no_topics, random_state=1, alpha=.1, l1_ratio=.5, init='nndsvd').fit(tfidf)
nmf_W = nmf_model.transform(tfidf)
nmf_H = nmf_model.components_

display_topics(nmf_H, nmf_W, tfidf_feature_names, documents, no_top_words, no_top_documents)

document.save('five_topics.docx')

# %% fifteen topics

no_topics = 15

document = Document()

# Run NMF
nmf_model = NMF(n_components=no_topics, random_state=1, alpha=.1, l1_ratio=.5, init='nndsvd').fit(tfidf)
nmf_W = nmf_model.transform(tfidf)
nmf_H = nmf_model.components_

display_topics(nmf_H, nmf_W, tfidf_feature_names, documents, no_top_words, no_top_documents)

document.save('fifteen_topics.docx')

# %% 10 topics

no_topics = 10

document = Document()

# NMF is able to use tf-idf
tfidf_vectorizer = TfidfVectorizer(max_df=0.95, min_df=2, stop_words='english')
tfidf = tfidf_vectorizer.fit_transform(documents)
tfidf_feature_names = tfidf_vectorizer.get_feature_names()

# Run NMF
nmf_model = NMF(n_components=no_topics, random_state=1, alpha=.1, l1_ratio=.5, init='nndsvd').fit(tfidf)
nmf_W = nmf_model.transform(tfidf)
nmf_H = nmf_model.components_

display_topics(nmf_H, nmf_W, tfidf_feature_names, documents, no_top_words, no_top_documents)

document.save('ten_topics.docx')

# %% so I selected 10 topics. Let's dump the whole thing to R

# this bit works and produces a list of topic headings
# and in the same order to top words from those headings

topic_heading  = []
topic_words = []

for topic_idx, topic in enumerate(nmf_H):
    topic_heading.append("Topic %d:" % (topic_idx))
    topic_words.append(" ".join([tfidf_feature_names[i]
                    for i in topic.argsort()[:-no_top_words - 1:-1]]))

# topic_heading
# topic_words

# %% this next bit is to write which topic every document belongs to

results = np.apply_along_axis(lambda x : np.argmax(x), 1, nmf_W)

feedback["topic"] = results

# save the topic models

feedback.to_feather('topic_modelled.feather')

# now save what they are

pd.DataFrame(topic_words, columns = ["words"]).to_feather("topics.feather")
