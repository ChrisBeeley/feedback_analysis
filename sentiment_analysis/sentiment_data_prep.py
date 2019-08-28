
# %% markdown

The code in this notebook and the run_classifier.py file in this repository is provided
for information but it will not work without being deployed properly within a working
copy of BERT as described in
[here](https://towardsdatascience.com/beginners-guide-to-bert-for-multi-classification-task-92f5445c2d7c)

Note further that run_classifier.py is itself from the BERT installation but requires modification
in place to make it work, as described in the link above.

# %%

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split

df_all = pd.read_csv('for_gensim.csv')

# cast ImpCrit to integer

df_all.dropna(subset=['ImpCrit'], inplace = True)

df_all["ImpCrit"] = df_all["ImpCrit"].astype("int32")

df_all = df_all[df_all.ImpCrit.isin([1, 2, 3])]

df_all = df_all[df_all.Division2.isin(["Local partnerships- MH", "Forensic services"])]

df_all.ImpCrit = df_all.ImpCrit.replace(3, 2)

df_all["ImpCrit"].value_counts()

# %% convert data to object for output to BERT

df_train, df_test = train_test_split(df_all, test_size=0.5)

# create a new dataframe for train, dev data

df_bert = pd.DataFrame({'guid': df_train['comment'],
    'label': df_train['ImpCrit'],
    'alpha': ['a']*df_train.shape[0],
    'text': df_train['Improve']})

#split into test, dev
df_bert_train, df_bert_dev = train_test_split(df_bert, test_size=0.01)

#create new dataframe for test data

df_bert_test = pd.DataFrame({'guid': df_test['comment'],
    'text': df_test['Improve']})

#output tsv file, no header for train and dev
df_bert_train.to_csv('train.tsv', sep='\t', index=False, header=False)
df_bert_dev.to_csv('dev.tsv', sep='\t', index=False, header=False)
df_bert_test.to_csv('test.tsv', sep='\t', index=False, header=True)

# %% save in a format that BERT likes

df_bert.to_csv('train.tsv', sep='\t', index=False, header=False)
