
# %% packages

import pandas as pd
import gensim
import gensim.downloader as api
from gensim import corpora
import inspect
from gensim.parsing.preprocessing import remove_stopwords

# %% data

improve = pd.read_csv("/home/chris/Nextcloud/feedback_analysis/for_gensim.csv", encoding = "latin-1", na_values=[])
best = pd.read_feather("/home/chris/Nextcloud/feedback_analysis/gensim_phraser/best.feather")

improve.Improve = improve.Improve.apply(lambda x: remove_stopwords(x))
best.Best = best.Best.apply(lambda x: remove_stopwords(x))

improve_list = improve.Improve.tolist()
best_list = best.Best.tolist()

# %% tokenise and process

# tokenize documents with gensim's tokenize() function
tokens_improve = [list(gensim.utils.tokenize(doc, lower=True)) for doc in improve_list]
tokens_best = [list(gensim.utils.tokenize(doc, lower=True)) for doc in best_list]

# build bigram model
bigram_improve = gensim.models.phrases.Phrases(tokens_improve, min_count=1, threshold=2)
bigram_best = gensim.models.phrases.Phrases(tokens_best, min_count=1, threshold=2)

# apply bigram model on tokens

bigrams_improve = bigram_improve[tokens_improve]
bigrams_best = bigram_best[tokens_best]

from sacremoses import MosesTokenizer, MosesDetokenizer

mt = MosesDetokenizer('en')
mt.detokenize(['Hello', 'World', '!'])

# %% save data

improve["bigram_improve"] = [mt.detokenize(x) for x in list(bigrams_improve)]

best["bigram_best"] = [mt.detokenize(x) for x in list(bigrams_best)]

improve.to_feather("improve_bigrams.feather")
best.to_feather("best_bigrams.feather")
