# statute-retrieval

### tags: AILA 2019, FIRE 2019, legal-information-retrieval

This repository containes python notebooks used in the thesis work 'Improving Legal Statute Retrieval using Relevance Weighting'.

### Statute retrieval task
We have Indian law statute documents (197) and queries (50) taken from [AILA FIRE 2019](https://sites.google.com/view/fire-2019-aila/track-description). The objective is to improve retrieval accuracy (measured in _MAP_)

### Dataset
It is available under `dataset` directory. Run `./dataset_prepare.sh `

### Requirements
**For Ubuntu**  
Download and extract terrier 4.x preferably, [terrier4.2](http://terrier.org/download/agree.shtml?terrier-core-4.2-bin.tar.gz).  
Install python3 (3.6 or greater) and pip3.
- Create a venv in this project directory (virtual environment is inbuilt with python3)
    + `python3.6 -m venv env    #python3.x as per your install`
- You should have a `bin/` `include/` `lib/` under `env` directory. Activate it -
    + `source env/bin/activate`
- Your terminal prompt should now have a (env) prefix. Then install these packages and run the other commands
    + `pip install nltk ipykernel gensim jupyter ipython numpy pandas`
    + `python -m nltk.downloader 'punkt' 'stopwords' 'averaged_perceptron_tagger'`
    + `python -m ipykernel install --user --name=statute-kernel  #this will show a success message`
- You can now start a jupyter notebook server. And you can connect with it via your internet browser.
    + `jupyter notebook`
- And open and run the notebooks in your browser. *Remember: Open any notebook. Go to Kernel menu > Change kernel > "statute-kernel"*.

### Baseline
1. Y. Shao et al. _THUIR@ AILA 2019: Information Retrieval Approaches for Identifying Relevant Precedents and Statutes_ [paper](https://pdfs.semanticscholar.org/4ce8/6e1c5878e2194fb27172fd3c577f8315d009.pdf)
2. Lefoane et al. _Legal Statutes Retrieval: A Comparative Approach on Performance of Title and Statutes Descriptive Text_ [paper](http://ceur-ws.org/Vol-2517/T1-9.pdf)
3. Mandal et al. _Unsupervised Identification of Relevant Cases & Statutes Using Word Embeddings_ [paper](https://pdfs.semanticscholar.org/33fe/66dd932ac44cb02ddeab89509d9a971336b5.pdf)

We obtained the baseline codes from Y. Shao et al ([here](https://drive.google.com/file/d/1Nou-CVJwmuelfX-MBPOIEJzZPZM_yQ6c/view?usp=drive_web)), Mandal et al ([code](https://drive.google.com/open?id=1ZEmq3VWBx2j6fquzcvxW-8MfBsXTJXL4),[model](https://drive.google.com/open?id=1MHxNZ49LO6UGRYZh19Utbo-M0d2d_XnD)).

Although baselines 1 and 2 were able to match the results in the AILA Overview paper, our attempt for baseline 3 was significantly below the expected result. Their approach involved manual keyphrase selection which we didn't perform. We retain our best-attempt calling it as baseline 3.

I've directly provided the score file (query-statue pair score in TREC-like format) under `baselines` directory. The format is 5 space-separated values. It goes like this -  
_Ex:_ q1 Q0 170 1 0.8837118244094455 run1(H\*SH)  
which means the baseline method for AILA_Q1 assigned S170 a score of 0.8837118244094455.  
Q0 is a fixed string. run1(H\*SH) is a title assigned by me to this scoring scheme.  
The 4th value (in this case "1") is denoting rank of S170 score for AILA_Q1. (*Note*: In some files, these ranks start with 0,1,2 and so on and in other files, the ranks start with 1,2,3 and so on.)

**IMPORTANT**:
- The scores in these files are **relative**. The comparison of scores only makes sense for a single query. In other words, other than the rank (4th value in each line), there is not much to infer from these files.
- In case of baseline2, there are some statue-query pair in the baseline file with no entries, it is because Terrier models omitted documents with score zero.
- I've followed the below prefixes for file names of baselines:
    + vsm2 : baseline1
    + IFB2 : baseline2
    + bert : baseline3


TODO: Explain how I generated these baseline files!

### Base Scoring (BM25 and LDA topic similarity)

#### BM25 scoring (_using Terrier_)

Ensure Terrier is installed.  
- `export TERRIER_HOME=<your-terrier-installation-path>`.
-  Then, run `./base-scoring/bm25-scoring.sh`.  
Result file will be generated at `base-scoring` directory. 

#### LDA topic similarity score
This was implemented in python using _gensim_ topic modeling library. Activate the virtual environment and then run `lda-scoring.py`.
- `source env/bin/activate`
- `cd base-scoring; python lda-scoring.py`

This will create a new directory (based on timestamp) with output score file `lda_base_score.res` and other extra files such as lda model files, dictionary of tokens in statute corpus, etc. 

#### Evaluation plan
Run `evaluate.sh` with a single arg that tells location of output score file.  
_Ex:_`./evaluate.sh base-scoring/2020-09-23_01-20-20/lda_base_score.res`
