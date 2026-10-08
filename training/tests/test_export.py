import importlib.util
from pathlib import Path
import numpy as np
ROOT = Path(__file__).resolve().parents[1]

def test_export_roundtrip(tmp_path):
    spec = importlib.util.spec_from_file_location('export', ROOT / 'src/export.py')
    assert spec and Path(spec.origin).exists(), 'portable exporter is missing'
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    from classifier import TransactionModel
    m = TransactionModel()
    x = m._featurize(['makan siang', 'beli makanan', 'gaji masuk', 'terima gaji'] * 3, fit=True)
    m.clf_category.fit(x, ['makanan','makanan','gaji','gaji']*3)
    m.clf_secondary.fit(x, ['makanan','makanan','gaji','gaji']*3)
    m.classes_category=list(m.clf_category.classes_); m.classes_secondary=list(m.clf_secondary.classes_)
    artifact=module.export_model(m,tmp_path/'model.json')
    assert artifact['format_version']==1
    assert artifact['primary']['classes']==m.classes_category
    count=len(artifact['word']['vocabulary'])+len(artifact['char']['vocabulary'])+8
    assert len(artifact['primary']['coefficients'][0])==count
    assert np.isfinite(artifact['primary']['coefficients']).all()
    for name in ('word','char'):
        assert sorted(artifact[name]['vocabulary'].values())==list(range(len(artifact[name]['idf'])))
