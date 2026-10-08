import csv, importlib.util, io
from pathlib import Path

def test_csv_quotes_titles_and_preserves_labels(tmp_path):
    path=Path(__file__).resolve().parents[1]/'src/export_feedback.py'
    assert path.exists(), 'feedback exporter missing'
    spec=importlib.util.spec_from_file_location('export_feedback',path)
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    output=tmp_path/'feedback.csv'
    rows=[('nasi, "enak"\nsekali','makanan','jajanan','manual','2026-10-08T00:00:00Z')]
    module.write_feedback(rows,output)
    result=list(csv.DictReader(io.StringIO(output.read_text())))
    assert result[0]['title']==rows[0][0]
    assert result[0]['category']=='makanan'
    assert result[0]['secondary_category']=='jajanan'
