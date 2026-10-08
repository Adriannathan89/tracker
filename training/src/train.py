"""Offline training/export. No HTTP server or in-request retraining."""
import argparse, hashlib, json, platform
from datetime import datetime, timezone
from pathlib import Path
import numpy, sklearn
from classifier import TransactionModel, _load_csv_with_secondary
from export import export_model
from fixtures import generate_fixtures

def main():
    root=Path(__file__).resolve().parents[2]
    p=argparse.ArgumentParser()
    p.add_argument('--dataset',type=Path,default=root/'training/data/transactions_v5_clean.csv')
    p.add_argument('--feedback',type=Path)
    p.add_argument('--output',type=Path,default=root/'models')
    p.add_argument('--fixtures',type=Path,default=root/'backend/crates/infrastructure/tests/fixtures/model-parity.json')
    args=p.parse_args()
    titles,primary,secondary=_load_csv_with_secondary(args.dataset)
    if args.feedback:
        t,c,s=_load_csv_with_secondary(args.feedback);titles+=t;primary+=c;secondary+=s
    if not titles: raise SystemExit('Dataset has no valid training rows')
    model=TransactionModel();metrics=model.train(titles,primary,secondary)
    artifact=args.output/'transaction-model.json';export_model(model,artifact)
    manifest={'format_version':1,'sha256':hashlib.sha256(artifact.read_bytes()).hexdigest(),
              'dataset_sha256':hashlib.sha256(args.dataset.read_bytes()).hexdigest(),
              'python':platform.python_version(),'sklearn':sklearn.__version__,'numpy':numpy.__version__,
              'trained_at':datetime.now(timezone.utc).isoformat(),'metrics':metrics}
    (args.output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    probes=['ngasih sumbangan ke kakak','dikasih makan sama kakak','dapat komisi dari tomoro',
            'bayar komisi ke tomoro','makan siang di warteg','gaji bulanan januari','!!!','yang dan di',
            'xyzzy zzunknown','  beli   beli nasi  ','CAFÉ café 🧋','transfer ke kakak','dari sama ke']
    generate_fixtures(model,probes+titles[::max(1,len(titles)//250)],args.fixtures)
    print(json.dumps(manifest,indent=2),flush=True)

if __name__=='__main__':main()
