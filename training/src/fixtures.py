import json
from pathlib import Path

def generate_fixtures(model, titles: list[str], output: Path) -> None:
    rows=[]
    for title in titles:
        x=model._featurize([title])
        p=model.clf_category.predict_proba(x)[0]; s=model.clf_secondary.predict_proba(x)[0]
        rows.append({'title':title,'category':model.classes_category[int(p.argmax())],
                     'secondary_category':model.classes_secondary[int(s.argmax())],
                     'primary_probabilities':p.tolist(),'secondary_probabilities':s.tolist()})
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(json.dumps(rows,ensure_ascii=False),encoding='utf-8')
