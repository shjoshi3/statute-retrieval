'''
Usage: python3.6 rf1_sq.py <scorefile> <frequencyfile>

'''
import sys
from math import log2

if len(sys.argv)>2:
    scorefile = sys.argv[1]
    freqfile = sys.argv[2]
else:
    print('Usage: python3.6 rf1_sq.py <scorefile> <frequencyfile>')
    exit(1)

freqfilename=freqfile.split('/')[-1]
freqfilepath=freqfile[:-len(freqfilename)]
scorefilename=scorefile.split('/')[-1]
rf = {}      #stores relevant frequency
n_queries = 40

with open(freqfile, 'r') as f:
    '''
    Format for freqfile: (BASH uniq -c output-like)
    <frequency> <statute-id>\n
    <frequency> <statute-id>\n    
    '''

    for line in f.readlines():
        line = line.strip()
        fq, *sid = line.split()
        sid = sid[0].strip()
        if sid.startswith("S"):
            sid = sid[1:]
        rf[int(sid)] = int(fq)

    
    for k in rf:
        rf[k] = log2(1 + (rf[k]+1)/n_queries)
             
#noting the weights 
weights={ '{:02d}'.format(k):v for k,v in rf.items() }
weights['default'] = log2(1 + 1/n_queries)

#saving the weights to a json file
import json
with open(freqfilepath+'/rf_weights_'+freqfilename+'.json', 'w', encoding='utf-8') as f:
   json.dump(weights, f, indent=2, sort_keys=True)

from collections import defaultdict
newscores = defaultdict(list)

with open(scorefile, 'r') as fin:
    '''
    Format for scorefile:
    <queryid> Q0 <statute-id> <some-integer> <score> <some-string>\n
    <queryid> Q0 <statute-id> <some-integer> <score> <some-string>\n
    '''
    
    factor = log2(1 + 1/n_queries)  # default rf weight
    
    for line in fin.readlines():
        line = line.split() 
        score,sid = float(line[4]), line[2]
        if sid.startswith("S"):
            sid = int(sid[1:])
        
        if sid in rf:
            score *= rf[sid]
        else:
            score *= factor

        newscores[line[0]].append((score, sid))


with open(scorefile+'.rf.res','w', encoding='utf-8') as fout:        
    
    for qry in newscores:
        rank=0
        for score, sid in sorted(newscores[qry], reverse=True):
            fout.write(qry+' Q0 S'+str(sid)+' '+str(rank)+' '+str(score)+' '+scorefilename+'_'+freqfilename+'_rf'+'\n')
            rank+=1
