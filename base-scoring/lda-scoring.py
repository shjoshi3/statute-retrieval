#Some paramaters
MIN_BIGRAM_COUNT = 10
NUM_TOPICS_LDA = 100
TOPIC_PROB_THRESHOLD = 0.03

OUTPUT_FILE = 'lda_base_score.res'

#Read statute documents
import glob
files = glob.glob('../dataset/AILA-dataset/AILA-data/Object_statutes/*.txt')
docs = []
fileids = []
print('Loading files')
for f in files:
    fh = open(f, 'r', encoding='utf8')
    docs.append(fh.read())
    fileids.append(f.split('/')[-1])
    fh.close()

# Text processing
from nltk.stem.wordnet import WordNetLemmatizer
from nltk.tokenize import RegexpTokenizer

print('Processing text')
tokenizer =  RegexpTokenizer(r'\w+')  # \w -> [a-zA-z0-9]
lemmatizer = WordNetLemmatizer()

statutes = []
for idx in range(len(docs)):
    #split into words; no lowercasing
    tokens = tokenizer.tokenize(docs[idx])
    #remove numbers and single characters
    tokens = [t for t in tokens if not t.isnumeric() and len(t)>1]
    #Lemmatize
    tokens = [lemmatizer.lemmatize(t) for t in tokens]
    statutes.append(tokens)

# Compute bigrams.
from gensim.models import Phrases
bigram = Phrases(statutes, min_count=MIN_BIGRAM_COUNT)
for idx in range(len(statutes)):
    for token in bigram[statutes[idx]]:
        if '_' in token:
            statutes[idx].append(token)

#Build dictionary
from gensim.corpora import Dictionary
# Create a dictionary representation of the documents.
dictionary = Dictionary(statutes)

from nltk.corpus import stopwords
stoplist = [s for s in stopwords.words('english') if "'" not in s]
stoplist += [s[:1].upper()+s[1:] for s in stoplist]
stop_ids = [
    dictionary.token2id[stopword]
    for stopword in stoplist
    if stopword in dictionary.token2id
]

dictionary.filter_tokens(stop_ids)
dictionary.compactify()  # remove gaps in id sequence after words that were removed

print('Stopword removal:')
print('Number of unique tokens: %d' % len(dictionary))

# Filter out words that occur less than 2 documents, or more than 100% of the documents.
dictionary.filter_extremes(no_below=2, no_above=1.0)

# Bag-of-words representation of the documents.
corpus = [dictionary.doc2bow(statute) for statute in statutes]

print('\nFilter rare words:')
print('Number of unique tokens: %d' % len(dictionary))
print('Number of documents: %d' % len(corpus))

	
#Build LDA model
from gensim.models import LdaModel

# Set training parameters.
num_topics = NUM_TOPICS_LDA
chunksize = 3000
passes = 20
iterations = 400
eval_every = None  # None -> Don't evaluate model perplexity, takes too much time.

# Make a index to word dictionary.
temp = dictionary[0]  # This is only to "load" the dictionary.
id2word = dictionary.id2token

print('\nStarting LDA model training')
model = LdaModel(
    corpus=corpus,
    id2word=id2word,
    chunksize=chunksize,
    alpha='auto',
    eta='auto',
    iterations=iterations,
    num_topics=num_topics,
    passes=passes,
    eval_every=eval_every
)

#Querying
print('Reading queries')
qf = open('../dataset/AILA-dataset/AILA-data/Query_doc.txt', 'r', encoding='utf8')
queries = []
for l in qf.readlines():
    #split into words; no lowercasing
    tokens = tokenizer.tokenize(l)
    #remove numbers and single characters
    tokens = [t for t in tokens[1:] if not t.isnumeric() and len(t)>1]
    #Lemmatize
    tokens = [lemmatizer.lemmatize(t) for t in tokens]
    queries.append(tokens)
qf.close()
for idx in range(len(queries)):
    for token in bigram[queries[idx]]:
        if '_' in token:
            queries[idx].append(token)
corpus_q = [dictionary.doc2bow(q) for q in queries]

#Calculate Topic probability similarity with THRESHOLD
print('Calculating scores')
import numpy as np
from math import sqrt 

thresh = TOPIC_PROB_THRESHOLD
num_topics = model.num_topics
index = np.zeros( (len(corpus),num_topics) )
for idx in range(len(corpus)):
    top_dist = model.get_document_topics(corpus[idx], minimum_probability=thresh)
    norm = 0
    for top, prob in top_dist:
        norm += prob*prob
    if norm==0:
        continue
    norm = sqrt(norm)    
    for top, prob in top_dist:
        index[idx][top] = prob/norm  #normalized for cosine similarity

#write output
import os, datetime
out_dir = os.path.join(os.getcwd(), datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S'))
os.makedirs(out_dir)
out_path = os.path.join(out_dir, OUTPUT_FILE)

with open(out_path,'w') as f:
    for idx in range(len(corpus_q)):
        top_q = model.get_document_topics(corpus_q[idx], minimum_probability=0)
        vec_q = np.array([prob for top, prob in top_q])
        vec_q /= np.linalg.norm(vec_q)  #normalize
        sims = np.zeros( len(corpus) )
        for idy in range(len(corpus)):
            vec_doc = index[idy]
            sims[idy] = np.dot(vec_q, vec_doc)
        ctr = 1
        for doc, score in sorted(enumerate(sims), key=lambda o: -o[1]): 
            f.write('AILA_Q'+str(idx+1))
            f.write(' Q0 S'+fileids[doc][1:-4])
            f.write(' '+str(ctr)+' ')
            f.write(str(score)+ ' ' + OUTPUT_FILE + '\n')
            ctr+=1

#Save LDA model
lda_path = os.path.join(out_dir, "ldamodel")
os.makedirs(lda_path)
model_name=os.path.join(lda_path,"lda_"+str(model.num_topics))
model.save(model_name)

#Save corpora dictionary
dic_path = os.path.join(out_dir, "dictionary.txt")
dictionary.save_as_text(dic_path, sort_by_word=True)
object_path = os.path.join(out_dir, "dictionary.object")
dictionary.save(object_path)