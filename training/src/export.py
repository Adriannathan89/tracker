"""Export learned sklearn parameters; the production runtime reads only JSON."""
import json
from pathlib import Path
from classifier import STOPWORDS_ID, IN_CUES, OUT_CUES, INCOME_CATEGORIES, VALID_SECONDARY_CATEGORIES

def export_model(model, output: Path) -> dict:
    def vector(v):
        return {'vocabulary': {k:int(i) for k,i in v.vocabulary_.items()}, 'idf':v.idf_.tolist(),
                'ngram_range':list(v.ngram_range),'sublinear_tf':v.sublinear_tf,'norm':v.norm}
    def classifier(c):
        weights=c.coef_; bias=c.intercept_
        # sklearn binary LR uses sigmoid; two half-logit rows give equivalent softmax.
        if len(c.classes_)==2:
            import numpy as np
            weights=np.vstack((-weights[0]/2,weights[0]/2));bias=np.array([-bias[0]/2,bias[0]/2])
        return {'classes':c.classes_.tolist(),'coefficients':weights.tolist(),'intercepts':bias.tolist()}
    a={'format_version':1,'preprocessing':{'stopwords':sorted(STOPWORDS_ID)},
       'word':vector(model.text_feats.transformer_list[0][1]),
       'char':vector(model.text_feats.transformer_list[1][1]),
       'money':{'in_cues':IN_CUES,'out_cues':OUT_CUES,'feature_count':8},
       'primary':classifier(model.clf_category),'secondary':classifier(model.clf_secondary),
       'income_categories':sorted(INCOME_CATEGORIES),
       'secondary_categories':{k:sorted(v) for k,v in VALID_SECONDARY_CATEGORIES.items()}}
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(json.dumps(a,separators=(',',':'),allow_nan=False),encoding='utf-8')
    return a
